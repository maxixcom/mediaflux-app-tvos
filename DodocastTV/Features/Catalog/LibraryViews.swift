import SwiftUI

/// «Медиатека»: библиотеки (проекты), подборки (плейлисты) и каналы — лентами.
struct LibraryIndexView: View {
    struct Index {
        let libraries: [LibraryRef]
        let playlists: [PlaylistItem]
        let channels: [ChannelItem]
    }

    var body: some View {
        Loadable(load: { c in
            async let libraries = c.libraries()
            async let playlists = c.playlists()
            async let channels = c.channels()
            return Index(libraries: try await libraries, playlists: try await playlists, channels: try await channels)
        }, content: { index in
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 48) {
                    if !index.libraries.isEmpty {
                        Row(title: String(localized: "Библиотеки"), items: index.libraries) { LibraryCard(item: $0) }
                    }
                    if !index.playlists.isEmpty {
                        Row(title: String(localized: "Подборки"), items: index.playlists) { PlaylistCard(item: $0) }
                    }
                    if !index.channels.isEmpty {
                        Row(title: String(localized: "Каналы"), items: index.channels) { ChannelCard(item: $0) }
                    }
                }
                .padding(.vertical, 40)
            }
        }, reloadOnViewerChange: true)
    }
}

/// Библиотека — сетка с подгрузкой страниц по мере прокрутки.
struct LibraryView: View {
    @Environment(AppModel.self) private var app
    let ref: LibraryRef

    @State private var title: String?
    @State private var items: [MediaItem] = []
    @State private var total = 0
    @State private var page = 0
    @State private var loading = false
    @State private var error: AppError?

    private let columns = [GridItem(.adaptive(minimum: CardSize.width, maximum: CardSize.width), spacing: 48)]

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 32) {
                Text(title ?? ref.title).font(.title2.weight(.semibold))
                LazyVGrid(columns: columns, alignment: .leading, spacing: 56) {
                    ForEach(items) { item in
                        MediaCard(item: item).onAppear {
                            if item.id == items.last?.id { Task { await loadMore() } }
                        }
                    }
                }
                if loading { ProgressView().frame(maxWidth: .infinity) }
                if let error {
                    Text(error.message).foregroundStyle(.secondary)
                    Button("Повторить") { Task { await loadMore() } }
                }
            }
            .padding(80)
        }
        .task { if items.isEmpty { await loadMore() } }
        .onChange(of: app.viewerRevision) { Task { await reloadLoaded() } }
    }

    /// Своё изменение состояния зрителя (MF-116): перечитать уже загруженные страницы — полосы и сердечки на карточках
    /// свежие, прокрутка на месте. Сбой — остаётся прежнее (кроме «нужен вход»).
    private func reloadLoaded() async {
        guard !loading, page > 0, let catalog = app.catalog else { return }
        loading = true
        defer { loading = false }
        do {
            var fresh: [MediaItem] = []
            for p in 0..<page {
                guard let data = try await catalog.library(ref.id, page: p) else { return }
                fresh += data.items.filter { new in !fresh.contains { $0.id == new.id } }
                total = data.totalCount
            }
            items = fresh
        } catch is CancellationError {
        } catch {
            let e = AppError.from(error)
            if e.isAppWide { await app.handle(e) }
        }
    }

    private func loadMore() async {
        guard !loading, items.isEmpty || items.count < total, let catalog = app.catalog else { return }
        loading = true
        defer { loading = false }
        do {
            guard let p = try await catalog.library(ref.id, page: page) else {
                error = AppError(.notFound)
                return
            }
            title = p.title
            items += p.items.filter { new in !items.contains { $0.id == new.id } }
            total = p.totalCount
            page += 1
            error = nil
        } catch {
            let e = AppError.from(error)
            if e.isAppWide { await app.handle(e) } else { self.error = e }
        }
    }
}

/// Подборка (плейлист): состав по порядку и «В избранное».
struct PlaylistView: View {
    @Environment(AppModel.self) private var app
    let id: String

    var body: some View {
        Loadable(load: { try await $0.playlist(id) }, content: { detail in
            if let detail {
                PlaylistContent(detail: detail)
            } else {
                Text(AppError(.notFound).message)
            }
        }, reloadOnViewerChange: true)
    }
}

private struct PlaylistContent: View {
    @Environment(AppModel.self) private var app
    @State var detail: PlaylistDetail
    @State private var play: PlayRequest?
    private let columns = [GridItem(.adaptive(minimum: CardSize.width, maximum: CardSize.width), spacing: 48)]

    var body: some View {
        ScrollView(.vertical) {
            VStack(alignment: .leading, spacing: 32) {
                HStack(alignment: .firstTextBaseline, spacing: 40) {
                    Text(detail.playlist.title).font(.title2.weight(.semibold))
                    Text(Format.itemCount(detail.playlist.itemCount)).foregroundStyle(.secondary)
                }
                if let description = detail.description, !description.isEmpty {
                    Text(description).foregroundStyle(.secondary).frame(maxWidth: 1400, alignment: .leading)
                }
                HStack(spacing: 32) {
                    if let first = detail.items.first {
                        // Подборка подряд: после конца элемента — следующий (с его позиции, если начат).
                        Button("Смотреть подборку", systemImage: "play.fill") {
                            play = .media(first.id, start: .resume, queue: detail.items.dropFirst().map(\.id))
                        }
                    }
                    FavoriteButton(target: .playlist(detail.playlist.id), isOn: $detail.playlist.favorite)
                }
                LazyVGrid(columns: columns, alignment: .leading, spacing: 56) {
                    ForEach(detail.items) { MediaCard(item: $0) }
                }
            }
            .padding(80)
        }
        .fullScreenCover(item: $play) { PlayerView(request: $0) }
    }
}

/// Канал — как карточка медиа: обложка слева (первого ролика программы, своей у канала нет), справа название,
/// «в эфире», описание, «Смотреть» (живой эфир, без позиции) и избранное.
struct ChannelView: View {
    @State var item: ChannelItem
    @State private var play: PlayRequest?

    var body: some View {
        HStack(alignment: .top, spacing: 64) {
            RemoteImage(url: item.coverURL, placeholder: "tv")
                .frame(width: 880, height: 495)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 28) {
                Text(item.title).font(.title2.weight(.semibold)).lineLimit(3)
                if item.onAir { OnAirBadge() } else { Text("Не в эфире").foregroundStyle(.secondary) }
                if let description = item.description, !description.isEmpty {
                    Text(description).font(.callout).foregroundStyle(.secondary).lineLimit(6)
                }
                HStack(spacing: 32) {
                    Button("Смотреть", systemImage: "play.fill") { play = .channel(item.id) }
                    FavoriteButton(target: .channel(item.id), isOn: $item.favorite)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(80)
        .frame(maxHeight: .infinity, alignment: .top)
        .fullScreenCover(item: $play) { PlayerView(request: $0, description: item.description) }
    }
}

/// «В избранное» / «В избранном»: сразу меняет вид, при отказе сервера возвращает как было.
struct FavoriteButton: View {
    @Environment(AppModel.self) private var app
    let target: FavoriteTarget
    @Binding var isOn: Bool
    @State private var busy = false

    var body: some View {
        Button {
            toggle()
        } label: {
            Label(isOn ? "В избранном" : "В избранное", systemImage: isOn ? "heart.fill" : "heart")
        }
        .disabled(busy)
    }

    private func toggle() {
        guard let catalog = app.catalog else { return }
        let new = !isOn
        isOn = new
        busy = true
        Task {
            defer { busy = false }
            do {
                try await catalog.setFavorite(target, new)
                app.viewerChanged()
            } catch {
                isOn = !new
                let e = AppError.from(error)
                if e.isAppWide { await app.handle(e) }
            }
        }
    }
}
