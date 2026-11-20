import SwiftUI

/// Карточка медиа: обложка, название, длительность, описание; «Смотреть» или «Продолжить с …» и «С начала»,
/// «Просмотрено», «В избранное».
struct MediaDetailView: View {
    let id: String

    var body: some View {
        Loadable(load: { try await $0.media(id) }, content: { item in
            if let item {
                MediaDetailContent(item: item)
            } else {
                Text(AppError(.notFound).message)
            }
        })
    }
}

private struct MediaDetailContent: View {
    @Environment(AppModel.self) private var app
    @State var item: MediaItem
    @State private var busy = false
    @State private var error: AppError?
    @State private var play: PlayRequest?

    var body: some View {
        HStack(alignment: .top, spacing: 64) {
            RemoteImage(url: item.coverURL)
                .frame(width: 880, height: 495)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 28) {
                Text(item.title).font(.title2.weight(.semibold)).lineLimit(3)
                    // Сценарии проверяют по нему, что открыта нужная карточка (главная остаётся в дереве под ней).
                    .accessibilityIdentifier("media-detail-title")
                meta
                if let description = item.description, !description.isEmpty {
                    Text(description).font(.callout).foregroundStyle(.secondary).lineLimit(6)
                }
                actions
                if let error { Text(error.message).foregroundStyle(.red) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(80)
        .frame(maxHeight: .infinity, alignment: .top)
        .fullScreenCover(item: $play, onDismiss: refresh) { request in
            PlayerView(request: request, description: item.description)
        }
    }

    /// После плеера — свежая позиция и отметка «просмотрено».
    private func refresh() {
        guard let catalog = app.catalog else { return }
        Task {
            if var fresh = try? await catalog.media(item.id) {
                fresh.description = fresh.description ?? item.description
                item = fresh
            }
        }
    }

    @ViewBuilder private var meta: some View {
        HStack(spacing: 24) {
            if let d = item.durationMs { Text(Format.duration(d)) }
            if item.watched {
                Label("Просмотрено", systemImage: "checkmark")
            } else if let resume = item.resumeMs {
                Text("Остановились на \(Format.position(resume))")
            }
        }
        .foregroundStyle(.secondary)
    }

    @ViewBuilder private var actions: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 32) {
                if let resume = item.resumeMs {
                    Button("Продолжить с \(Format.position(resume))", systemImage: "play.fill") {
                        play = .media(item.id, start: .resume)
                    }
                    Button("С начала", systemImage: "arrow.counterclockwise") {
                        play = .media(item.id, start: .beginning)
                    }
                } else {
                    Button("Смотреть", systemImage: "play.fill") { play = .media(item.id, start: .beginning) }
                }
            }
            HStack(spacing: 32) {
                Button {
                    setWatched(!item.watched)
                } label: {
                    Label(item.watched ? "Не просмотрено" : "Просмотрено",
                          systemImage: item.watched ? "arrow.uturn.backward" : "checkmark")
                }
                .disabled(busy)
                FavoriteButton(target: .media(item.id), isOn: $item.favorite)
            }
        }
    }

    private func setWatched(_ watched: Bool) {
        guard let catalog = app.catalog else { return }
        busy = true
        Task {
            defer { busy = false }
            do {
                let p = try await catalog.markWatched(item.id, watched)
                item.progress = ViewProgress(positionMs: p.positionMs, durationMs: item.durationMs, watched: p.watched)
                error = nil
                app.viewerChanged()
            } catch {
                let e = AppError.from(error)
                if e.needsSignIn { await app.handle(e) } else { self.error = e }
            }
        }
    }
}
