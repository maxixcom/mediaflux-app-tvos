import AVFoundation
import Observation
import UIKit

/// Сеанс просмотра: «начать просмотр» → штатный AVPlayer → позиция в app-api (§7, §8).
///
/// - Старт: `playbackStart` (токен на сеанс), затем позиция возобновления или начало.
/// - Главы — маркеры навигации с картинками; «Инфо» — название, описание, обложка (`externalMetadata`).
/// - Позиция: раз в 15 с во время игры; пауза, конец, выход, фон — `final`. У канала позиции нет.
/// - Подборка: после конца элемента — следующий.
/// - Токен потока живёт 12 ч: за 5 минут до срока берём новый и продолжаем с той же позиции.
@MainActor
@Observable
final class PlayerModel {
    enum State: Equatable {
        case loading
        case playing
        case failed(AppError)
    }

    private(set) var state: State = .loading
    let player = AVPlayer()

    private let catalog: Catalog
    private let sender: ProgressSender?
    private let description: String?
    private var start: PlayRequest.Start
    private var target: PlayRequest.Target
    private var queue: [String]

    private var mediaId: String?
    private var info: PlaybackInfo?
    private var lastSent = Date.distantPast
    /// Последний `final`: в конце ролика AVPlayer сам ставит паузу, и «конец» с «паузой» дали бы два одинаковых отчёта.
    private var lastFinal: (positionMs: Int, at: Date)?
    private var wasPlaying = false
    private var observers: [NSKeyValueObservation] = []
    private var timeObserver: Any?
    private var endObserver: NSObjectProtocol?
    private var expiryTask: Task<Void, Never>?

    static let tick: TimeInterval = 15

    init(request: PlayRequest, catalog: Catalog, sender: ProgressSender?, description: String? = nil) {
        self.catalog = catalog
        self.sender = sender
        self.description = description
        self.start = request.start
        self.target = request.target
        if case let .media(_, queue) = request.target { self.queue = queue } else { self.queue = [] }
    }

    var isLive: Bool { if case .channel = target { true } else { false } }

    func begin() async {
        switch target {
        case let .media(id, _): await play(mediaId: id)
        case .channel: await play(mediaId: nil)
        }
    }

    // MARK: - Старт

    private func play(mediaId: String?) async {
        state = .loading
        teardownItem()
        let info: PlaybackInfo
        do {
            info = try await catalog.playbackStart(target, mediaId: mediaId)
        } catch is CancellationError {
            return
        } catch {
            state = .failed(AppError.from(error))
            return
        }
        self.mediaId = mediaId
        self.info = info
        let item = AVPlayerItem(url: info.url)
        item.externalMetadata = Metadata.external(title: info.title, description: mediaId == nil ? nil : description,
                                                  artwork: nil)
        Chapters.attach(to: item, chapters: info.chapters, durationMs: info.durationMs,
                        previewManifest: info.previewManifestURL)
        loadArtwork(for: item, info: info)
        observe(item)
        player.replaceCurrentItem(with: item)

        let from = start == .resume ? (info.resumePositionMs ?? 0) : 0
        if !isLive, from > 0 {
            await player.seek(to: CMTime(value: CMTimeValue(from), timescale: 1000), toleranceBefore: .zero,
                              toleranceAfter: .zero)
        }
        player.play()
        state = .playing
        Log.line("плеер: \(isLive ? "канал" : "медиа \(mediaId ?? "")") с \(from / 1000) с, глав \(info.chapters.count)")
        scheduleRefresh(info)
    }

    /// Обложка во вкладку «Инфо» — когда загрузится, плеер её не ждёт.
    private func loadArtwork(for item: AVPlayerItem, info: PlaybackInfo) {
        guard let url = info.coverURL else { return }
        let title = info.title, description = mediaId == nil ? nil : self.description
        Task { @MainActor [weak item] in
            guard let image = await ImageLoader.shared.image(url), let jpeg = image.jpegData(compressionQuality: 0.85),
                  let item else { return }
            item.externalMetadata = Metadata.external(title: title, description: description, artwork: jpeg)
        }
    }

    // MARK: - Наблюдение

    private func observe(_ item: AVPlayerItem) {
        observers = [
            player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
                let status = player.timeControlStatus
                Task { @MainActor in self?.statusChanged(status) }
            },
            item.observe(\.status, options: [.new]) { [weak self] item, _ in
                let failed = item.status == .failed
                let message = item.error?.localizedDescription
                Task { @MainActor in
                    guard failed else { return }
                    Log.line("плеер: отказ элемента — \(message ?? "")")
                    self?.state = .failed(AppError(.playbackFailed))
                }
            }
        ]
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: Self.tick, preferredTimescale: 1),
                                                      queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.tickReport() }
        }
        endObserver = NotificationCenter.default.addObserver(forName: AVPlayerItem.didPlayToEndTimeNotification,
                                                             object: item, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.ended() }
        }
    }

    private func statusChanged(_ status: AVPlayer.TimeControlStatus) {
        switch status {
        case .playing:
            wasPlaying = true
        case .paused where wasPlaying:
            wasPlaying = false
            Task { await report(final: true) }
        default:
            break
        }
    }

    /// Такт отчёта. Наблюдатель AVPlayer зовётся и на перемотке, иногда дважды подряд, — поэтому «когда слали»
    /// отмечаем здесь же, синхронно, а не в асинхронной отправке: иначе второй вызов проскакивает проверку.
    private func tickReport() {
        guard player.timeControlStatus == .playing, Date().timeIntervalSince(lastSent) >= Self.tick - 3 else { return }
        lastSent = Date()
        Task { await report(final: false) }
    }

    private func ended() {
        Task {
            await report(final: true, positionMs: info?.durationMs)
            guard !queue.isEmpty else { return }
            let next = queue.removeFirst()
            Log.line("плеер: следующий в подборке — \(next)")
            start = .resume
            await play(mediaId: next)
        }
    }

    // MARK: - Позиция

    private var positionMs: Int {
        let s = CMTimeGetSeconds(player.currentTime())
        return s.isFinite ? Int(s * 1000) : 0
    }

    /// Отчёт о позиции. У канала позиции нет; «всё ещё ноль» после старта — не просмотр.
    func report(final: Bool, positionMs explicit: Int? = nil) async {
        guard let sender, let mediaId, !isLive else { return }
        let position = explicit ?? positionMs
        guard position >= 1000 else { return }
        if final {
            if let last = lastFinal, abs(last.positionMs - position) < 2000, Date().timeIntervalSince(last.at) < 5 { return }
            lastFinal = (position, Date())
        }
        lastSent = Date()
        let r = ProgressReport(mediaId: mediaId, positionMs: position, durationMs: info?.durationMs,
                               reportedAt: Date(), final: final)
        Log.line("позиция \(mediaId): \(position / 1000) с\(final ? " final" : "")")
        await sender.send(r)
    }

    // MARK: - Токен потока

    private func scheduleRefresh(_ info: PlaybackInfo) {
        expiryTask?.cancel()
        guard let expires = info.expiresAt else { return }
        let delay = expires.timeIntervalSinceNow - 300
        guard delay > 0 else { return }
        expiryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled else { return }
            await self?.refreshToken()
        }
    }

    /// Новый токен потока на том же месте: тот же медиа, позиция — текущая.
    private func refreshToken() async {
        let position = positionMs
        Log.line("плеер: токен потока истекает — продолжаем с новым с \(position / 1000) с")
        start = .beginning
        await play(mediaId: mediaId)
        if !isLive, position > 0 {
            await player.seek(to: CMTime(value: CMTimeValue(position), timescale: 1000))
        }
    }

    // MARK: - Конец сеанса

    /// Выход из плеера или уход в фон: последняя позиция — сразу.
    func stop() async {
        expiryTask?.cancel()
        player.pause()
        await report(final: true)
        teardownItem()
        player.replaceCurrentItem(with: nil)
    }

    private func teardownItem() {
        observers.forEach { $0.invalidate() }
        observers = []
        if let timeObserver { player.removeTimeObserver(timeObserver) }
        timeObserver = nil
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }
        endObserver = nil
        wasPlaying = false
    }
}
