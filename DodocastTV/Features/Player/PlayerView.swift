import AVKit
import SwiftUI

/// Экран плеера поверх всего: штатный `AVPlayerViewController` (меню звука, субтитров, главы, «Инфо» — его
/// собственные). Кнопка «Меню» на пульте закрывает плеер; позиция уходит при закрытии и уходе в фон.
struct PlayerView: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    let request: PlayRequest
    var description: String?
    @State private var model: PlayerModel?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let model {
                switch model.state {
                case .loading:
                    ProgressView()
                case .playing:
                    PlayerController(player: model.player).ignoresSafeArea()
                case let .failed(error):
                    VStack(spacing: 32) {
                        Text(error.message).multilineTextAlignment(.center).frame(maxWidth: 1100)
                        Button("Закрыть") { dismiss() }
                    }
                }
            }
        }
        .task {
            guard model == nil, let catalog = app.catalog else { return }
            let m = PlayerModel(request: request, catalog: catalog, sender: app.progressSender, description: description)
            model = m
            await m.begin()
            if case let .failed(e) = m.state, e.isAppWide {
                dismiss()
                await app.handle(e)
            }
        }
        .onDisappear {
            guard let model else { return }
            Task {
                await model.stop()
                // Финальная позиция ушла (или ждёт в ProgressOutbox) — ленты «Продолжить просмотр» и полосы перечитаются.
                if !model.isLive { app.viewerChanged() }
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active, let model { Task { await model.report(final: true) } }
        }
    }
}

private struct PlayerController: UIViewControllerRepresentable {
    let player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        vc.player = player
        return vc
    }

    func updateUIViewController(_ vc: AVPlayerViewController, context: Context) {}
}
