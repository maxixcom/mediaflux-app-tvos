import Foundation

/// Отчёт о позиции просмотра (§7): время — по часам устройства; между устройствами побеждает поздний.
struct ProgressReport: Codable, Equatable, Sendable {
    let mediaId: String
    let positionMs: Int
    let durationMs: Int?
    let reportedAt: Date
    let final: Bool
}

/// Недосланные отчёты — по одному на медиа (поздний заменяет ранний). Переживают перезапуск: лежат в UserDefaults
/// под ключом сервера. Досылаются при следующем удачном отчёте, на старте и перед выходом / сменой сервера.
actor ProgressOutbox {
    private let key: String
    private var pending: [String: ProgressReport]

    init(serverKey: String) {
        key = "progress.outbox.\(serverKey)"
        pending = (UserDefaults.standard.data(forKey: key))
            .flatMap { try? JSONDecoder().decode([String: ProgressReport].self, from: $0) } ?? [:]
    }

    var isEmpty: Bool { pending.isEmpty }

    func keep(_ report: ProgressReport) {
        if let old = pending[report.mediaId], old.reportedAt > report.reportedAt { return }
        pending[report.mediaId] = report
        save()
    }

    func drop(_ report: ProgressReport) {
        if pending[report.mediaId] == report {
            pending[report.mediaId] = nil
            save()
        }
    }

    func all() -> [ProgressReport] { Array(pending.values) }

    func clear() {
        pending = [:]
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func save() {
        UserDefaults.standard.set(try? JSONEncoder().encode(pending), forKey: key)
    }
}

/// Отправка позиции в app-api (`progressReport`):
/// - во время игры — раз в 15 с (такт задаёт плеер);
/// - пауза, выход из плеера, уход в фон, конец ролика — `final` (сервер пишет сразу);
/// - `RATE_LIMITED` — такт пропускаем, отчёт остаётся недосланным; сбой сети — тоже;
/// - позиция «всё ещё 0» после старта не шлётся: это не просмотр.
struct ProgressSender: Sendable {
    let api: API
    let outbox: ProgressOutbox

    func send(_ report: ProgressReport) async {
        if await deliver(report) {
            await flush()
        } else {
            await outbox.keep(report)
        }
    }

    /// Дослать всё, что не ушло раньше.
    func flush() async {
        for report in await outbox.all() {
            if await deliver(report) { await outbox.drop(report) } else { return }
        }
    }

    private func deliver(_ r: ProgressReport) async -> Bool {
        let input = DCAPI.ProgressReportInput(
            mediaId: r.mediaId,
            positionMs: r.positionMs,
            durationMs: r.durationMs.map { .some($0) } ?? .none,
            reportedAt: DateTimeFormat.string(r.reportedAt),
            final: .some(r.final)
        )
        do {
            _ = try await api.perform(DCAPI.ProgressReportMutation(input: input))
            return true
        } catch {
            let e = AppError.from(error)
            Log.line("позиция \(r.mediaId) \(r.positionMs / 1000) с\(r.final ? " final" : ""): не ушла — \(e.code)")
            return false
        }
    }
}
