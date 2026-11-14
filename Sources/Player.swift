import AVKit
import SwiftUI

/// Штатный плеер tvOS: меню звука, субтитров и маркеры глав — его собственные.
struct PlayerScreen: UIViewControllerRepresentable {
    let resolved: Resolved

    func makeCoordinator() -> PlaybackProbe {
        PlaybackProbe(label: resolved.label)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let item = AVPlayerItem(url: resolved.url)
        if !resolved.chapters.isEmpty {
            item.navigationMarkerGroups = [Chapters.group(resolved.chapters, durationMs: resolved.durationMs)]
        }
        let player = AVPlayer(playerItem: item)
        let vc = AVPlayerViewController()
        vc.player = player
        context.coordinator.attach(player: player, overlay: vc.contentOverlayView)
        Log.line("старт: \(resolved.label) live=\(resolved.live) глав=\(resolved.chapters.count)")
        player.play()
        runScenario(player)
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {}

    private func runScenario(_ player: AVPlayer) {
        if let to = Scenario.seekTo {
            DispatchQueue.main.asyncAfter(deadline: .now() + 8) { [weak player] in
                Log.line("сценарий: перемотка на \(to) с")
                player?.seek(to: CMTime(seconds: to, preferredTimescale: 1000)) { done in
                    Log.line("сценарий: перемотка \(done ? "выполнена" : "прервана"), позиция \(String(format: "%.1f", CMTimeGetSeconds(player?.currentTime() ?? .zero))) с")
                }
            }
        }
        guard let pauseAt = Scenario.pauseAfter else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + pauseAt) { [weak player] in
            Log.line("сценарий: ПАУЗА")
            player?.pause()
        }
        if let resume = Scenario.resumeAfter {
            DispatchQueue.main.asyncAfter(deadline: .now() + pauseAt + resume) { [weak player] in
                Log.line("сценарий: продолжение после паузы")
                player?.play()
            }
        }
    }

    static func dismantleUIViewController(_ vc: AVPlayerViewController, coordinator: PlaybackProbe) {
        coordinator.stop()
        vc.player?.pause()
        vc.player?.replaceCurrentItem(with: nil)
    }
}

enum Chapters {
    /// Главы конфига → маркеры навигации tvOS: конец главы — начало следующей, у последней — конец ролика.
    static func group(_ chapters: [PublicConfig.Chapter], durationMs: Int?) -> AVNavigationMarkersGroup {
        let sorted = chapters.sorted { $0.startMs < $1.startMs }
        let markers: [AVTimedMetadataGroup] = sorted.enumerated().map { index, ch in
            let endMs = index + 1 < sorted.count ? sorted[index + 1].startMs : (durationMs ?? ch.startMs + 1000)
            let range = CMTimeRange(start: CMTime(value: CMTimeValue(ch.startMs), timescale: 1000),
                                    duration: CMTime(value: CMTimeValue(max(endMs - ch.startMs, 1)), timescale: 1000))
            let title = AVMutableMetadataItem()
            title.identifier = .commonIdentifierTitle
            title.value = ch.title as NSString
            title.extendedLanguageTag = "und"
            return AVTimedMetadataGroup(items: [title], timeRange: range)
        }
        return AVNavigationMarkersGroup(title: nil, timedNavigationMarkers: markers)
    }
}

/// Прибор: раз в 10 с пишет в консоль и на экран, сколько скачано, и любые ошибки плеера.
/// Байты — сумма `numberOfBytesTransferred` по журналу доступа: по ней меряем трафик на паузе.
final class PlaybackProbe: NSObject {
    private let label: String
    private weak var player: AVPlayer?
    private var timer: Timer?
    private var observations: [NSKeyValueObservation] = []
    private var tokens: [NSObjectProtocol] = []
    private let overlay = UILabel()
    private let started = Date()
    private var lastBytes: Int64 = 0

    init(label: String) {
        self.label = label
    }

    func attach(player: AVPlayer, overlay host: UIView?) {
        self.player = player
        if let host {
            overlay.font = .monospacedSystemFont(ofSize: 22, weight: .regular)
            overlay.textColor = .white
            overlay.backgroundColor = UIColor.black.withAlphaComponent(0.55)
            overlay.numberOfLines = 0
            overlay.translatesAutoresizingMaskIntoConstraints = false
            host.addSubview(overlay)
            NSLayoutConstraint.activate([
                overlay.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 60),
                overlay.topAnchor.constraint(equalTo: host.topAnchor, constant: 40)
            ])
        }
        guard let item = player.currentItem else { return }

        observations.append(item.observe(\.status, options: [.new]) { [weak self] item, _ in
            switch item.status {
            case .readyToPlay:
                Log.line("готов к игре")
                self?.describeSelections(item)
            case .failed:
                Log.line("ОТКАЗ элемента: \(Self.describe(item.error))")
            default: break
            }
        })
        observations.append(player.observe(\.timeControlStatus, options: [.new]) { player, _ in
            let s: String
            switch player.timeControlStatus {
            case .paused: s = "пауза"
            case .playing: s = "играет"
            case .waitingToPlayAtSpecifiedRate: s = "ждёт: \(player.reasonForWaitingToPlay?.rawValue ?? "—")"
            @unknown default: s = "?"
            }
            Log.line("состояние: \(s)")
        })

        let nc = NotificationCenter.default
        tokens.append(nc.addObserver(forName: .AVPlayerItemNewErrorLogEntry, object: item, queue: .main) { _ in
            guard let e = item.errorLog()?.events.last else { return }
            Log.line("журнал ошибок: \(e.errorStatusCode) \(e.errorDomain) \(e.errorComment ?? "") uri=\(Self.shortURI(e.uri))")
        })
        tokens.append(nc.addObserver(forName: .AVPlayerItemFailedToPlayToEndTime, object: item, queue: .main) { n in
            Log.line("не доиграл: \(Self.describe(n.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? Error))")
        })
        tokens.append(nc.addObserver(forName: .AVPlayerItemPlaybackStalled, object: item, queue: .main) { _ in
            Log.line("застрял (stall)")
        })

        timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { [weak self] _ in self?.report() }
    }

    func stop() {
        report()
        Log.line("стоп: \(label)")
        timer?.invalidate()
        observations.removeAll()
        tokens.forEach(NotificationCenter.default.removeObserver)
        tokens.removeAll()
    }

    private func report() {
        guard let player, let item = player.currentItem else { return }
        let events = item.accessLog()?.events ?? []
        let bytes = events.reduce(Int64(0)) { $0 + max($1.numberOfBytesTransferred, 0) }
        let requests = events.reduce(0) { $0 + max($1.numberOfMediaRequests, 0) }
        let stalls = events.reduce(0) { $0 + max($1.numberOfStalls, 0) }
        let last = events.last
        let delta = bytes - lastBytes
        lastBytes = bytes
        let pos = CMTimeGetSeconds(player.currentTime())
        let mode = player.timeControlStatus == .paused ? "пауза" : "игра"
        let text = String(format: "+%4.0fс %@ поз=%.1fс скачано=%.2f МБ (+%.2f) запросов=%d застреваний=%d битрейт=%.0f кбит/с переключений=%d",
                          Date().timeIntervalSince(started), mode, pos,
                          Double(bytes) / 1_048_576, Double(delta) / 1_048_576, requests, stalls,
                          (last?.indicatedBitrate ?? 0) / 1000, events.count)
        Log.line(text)
        overlay.text = " \(label)\n \(text) "
    }

    private func describeSelections(_ item: AVPlayerItem) {
        let asset = item.asset
        Task {
            for (name, ch) in [("звук", AVMediaCharacteristic.audible), ("субтитры", .legible)] {
                let group = try? await asset.loadMediaSelectionGroup(for: ch)
                let opts = group?.options.map { "\($0.displayName)[\($0.extendedLanguageTag ?? "?")]" } ?? []
                Log.line("\(name): \(opts.isEmpty ? "нет" : opts.joined(separator: ", "))")
            }
        }
    }

    private static func describe(_ error: Error?) -> String {
        guard let e = error as NSError? else { return "—" }
        var s = "\(e.domain) \(e.code) \(e.localizedDescription)"
        if let u = e.userInfo[NSUnderlyingErrorKey] as? NSError { s += " ← \(u.domain) \(u.code)" }
        return s
    }

    /// Адрес без токена: путь после `/s/{jwt}/` и без запроса.
    private static func shortURI(_ uri: String?) -> String {
        guard let uri, let u = URL(string: uri) else { return "—" }
        let parts = u.path.split(separator: "/")
        if let i = parts.firstIndex(of: "s"), parts.count > i + 2 { return "/" + parts[(i + 2)...].joined(separator: "/") }
        return u.path
    }
}
