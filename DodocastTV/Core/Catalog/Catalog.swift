import Foundation

// Модели экранов каталога — свои, а не сгенерированные Apollo: экраны не зависят от формы запросов, а запросы можно
// менять, не трогая экраны.

struct ViewProgress: Hashable, Sendable {
    let positionMs: Int
    let durationMs: Int?
    let watched: Bool

    /// Доля просмотренного для полосы на карточке; без длительности полосы нет.
    func fraction(durationMs fallback: Int?) -> Double? {
        guard let d = durationMs ?? fallback, d > 0 else { return nil }
        return min(1, max(0, Double(positionMs) / Double(d)))
    }
}

struct MediaItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let durationMs: Int?
    let coverURL: URL?
    var favorite: Bool
    var progress: ViewProgress?
    var description: String?

    /// «Продолжить» — есть позиция и не досмотрено (то же правило, что у ленты на сервере: от 30 с).
    var resumeMs: Int? {
        guard let p = progress, !p.watched, p.positionMs >= 30_000 else { return nil }
        return p.positionMs
    }

    var watched: Bool { progress?.watched ?? false }
}

struct PlaylistItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let itemCount: Int
    let coverURL: URL?
    var favorite: Bool
}

struct ChannelItem: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let onAir: Bool
    var favorite: Bool
    var description: String?
}

enum FavoriteItem: Identifiable, Hashable, Sendable {
    case media(MediaItem)
    case playlist(PlaylistItem)
    case channel(ChannelItem)

    var id: String {
        switch self {
        case let .media(m): "m:\(m.id)"
        case let .playlist(p): "p:\(p.id)"
        case let .channel(c): "c:\(c.id)"
        }
    }
}

struct LibraryRef: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let itemCount: Int
    var coverURL: URL?
}

struct Shelf: Identifiable, Hashable, Sendable {
    let library: LibraryRef
    let items: [MediaItem]
    var id: String { library.id }
}

struct HomeData: Sendable {
    let continueWatching: [MediaItem]
    let recent: [MediaItem]
    let favorites: [FavoriteItem]
    let shelves: [Shelf]
    let channels: [ChannelItem]

    var isEmpty: Bool {
        continueWatching.isEmpty && recent.isEmpty && favorites.isEmpty && shelves.isEmpty && channels.isEmpty
    }
}

struct LibraryPage: Sendable {
    let title: String
    let description: String?
    let totalCount: Int
    let items: [MediaItem]
}

struct PlaylistDetail: Sendable {
    var playlist: PlaylistItem
    let description: String?
    let items: [MediaItem]
}

/// Цель избранного: ровно одно поле входа.
enum FavoriteTarget: Hashable, Sendable {
    case media(String), playlist(String), channel(String)

    var input: DCAPI.FavoriteTargetInput {
        switch self {
        case let .media(id): DCAPI.FavoriteTargetInput(mediaId: .some(id))
        case let .playlist(id): DCAPI.FavoriteTargetInput(playlistId: .some(id))
        case let .channel(id): DCAPI.FavoriteTargetInput(channelId: .some(id))
        }
    }
}

/// Чтение каталога и отметки зрителя поверх `API`.
struct Catalog: Sendable {
    let api: API

    func home() async throws -> HomeData {
        let h = try await api.fetch(DCAPI.HomeQuery()).home
        return HomeData(
            continueWatching: h.continueWatching.map { MediaItem($0.fragments.mediaCard) },
            recent: h.recent.map { MediaItem($0.fragments.mediaCard) },
            favorites: h.favorites.compactMap { f in
                if let m = f.asMedia { return .media(MediaItem(m.fragments.mediaCard)) }
                if let p = f.asPlaylist { return .playlist(PlaylistItem(p.fragments.playlistCard)) }
                if let c = f.asChannel { return .channel(ChannelItem(c.fragments.channelCard)) }
                return nil
            },
            shelves: h.shelves.map { s in
                Shelf(library: LibraryRef(id: s.library.id, title: s.library.title, itemCount: s.library.itemCount),
                      items: s.items.map { MediaItem($0.fragments.mediaCard) })
            },
            channels: h.channels.map { ChannelItem($0.fragments.channelCard) }
        )
    }

    func libraries() async throws -> [LibraryRef] {
        try await api.fetch(DCAPI.LibrariesQuery()).libraries.nodes.map {
            LibraryRef(id: $0.id, title: $0.title, itemCount: $0.itemCount, coverURL: $0.coverUrl.flatMap(URL.init(string:)))
        }
    }

    func library(_ id: String, page: Int, size: Int = 40) async throws -> LibraryPage? {
        let input = DCAPI.PageInput(page: .some(Int32(page)), size: .some(Int32(size)))
        guard let l = try await api.fetch(DCAPI.LibraryQuery(id: id, page: .some(input))).library else { return nil }
        return LibraryPage(title: l.title, description: l.description, totalCount: l.items.totalCount,
                           items: l.items.nodes.map { MediaItem($0.fragments.mediaCard) })
    }

    func playlists() async throws -> [PlaylistItem] {
        try await api.fetch(DCAPI.PlaylistsQuery()).playlists.nodes.map { PlaylistItem($0.fragments.playlistCard) }
    }

    func playlist(_ id: String) async throws -> PlaylistDetail? {
        guard let p = try await api.fetch(DCAPI.PlaylistQuery(id: id)).playlist else { return nil }
        return PlaylistDetail(playlist: PlaylistItem(p.fragments.playlistCard), description: p.description,
                              items: p.items.map { MediaItem($0.fragments.mediaCard) })
    }

    func channels() async throws -> [ChannelItem] {
        try await api.fetch(DCAPI.ChannelsQuery()).channels.map {
            var c = ChannelItem($0.fragments.channelCard)
            c.description = $0.description
            return c
        }
    }

    func media(_ id: String) async throws -> MediaItem? {
        guard let m = try await api.fetch(DCAPI.MediaQuery(id: id)).media else { return nil }
        var item = MediaItem(m.fragments.mediaCard)
        item.description = m.description
        return item
    }

    /// «Просмотрено» вручную; снятие отметки сбрасывает позицию на начало (сервер, §7).
    func markWatched(_ mediaId: String, _ watched: Bool) async throws -> ViewProgress {
        let p = try await api.perform(DCAPI.MarkWatchedMutation(mediaId: mediaId, watched: watched)).markWatched
        return ViewProgress(positionMs: p.positionMs, durationMs: nil, watched: p.watched)
    }

    func setFavorite(_ target: FavoriteTarget, _ on: Bool) async throws {
        if on {
            _ = try await api.perform(DCAPI.FavoriteAddMutation(target: target.input))
        } else {
            _ = try await api.perform(DCAPI.FavoriteRemoveMutation(target: target.input))
        }
    }
}

extension MediaItem {
    init(_ f: DCAPI.MediaCard) {
        id = f.id
        title = f.title
        durationMs = f.durationMs
        coverURL = f.coverUrl.flatMap(URL.init(string:))
        favorite = f.favorite
        progress = f.progress.map { ViewProgress(positionMs: $0.positionMs, durationMs: $0.durationMs, watched: $0.watched) }
        description = nil
    }
}

extension PlaylistItem {
    init(_ f: DCAPI.PlaylistCard) {
        self.init(id: f.id, title: f.title, itemCount: f.itemCount, coverURL: f.coverUrl.flatMap(URL.init(string:)),
                  favorite: f.favorite)
    }
}

extension ChannelItem {
    init(_ f: DCAPI.ChannelCard) {
        self.init(id: f.id, title: f.title, onAir: f.onAir, favorite: f.favorite, description: nil)
    }
}
