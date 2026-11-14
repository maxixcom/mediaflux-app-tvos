import Foundation

/// Конфиг витрины от стримера (STREAM_AUTHORIZATION.md §5): медиа, элемент плейлиста, канал.
struct PublicConfig: Decodable {
    struct Sources: Decodable {
        struct HLS: Decodable {
            let mp4: String?
            let ts: String?
        }

        let hls: HLS?
        // у канала адреса лежат прямо в sources, без уровня hls
        let mp4: String?
        let ts: String?
    }

    struct Chapter: Decodable {
        let startMs: Int
        let title: String
    }

    struct PlaylistItem: Decodable {
        let code: String
        let title: String?
        let locked: Bool?
    }

    let title: String?
    let encrypted: Bool?
    let durationMs: Int?
    let sources: Sources?
    let chapters: [Chapter]?
    // плейлист
    let token: String?
    let items: [PlaylistItem]?
    // канал
    let state: String?
}

enum Packaging: String, CaseIterable {
    case mp4, ts
}

/// Что играть: адрес мастер-плейлиста со свежим токеном и всё, что нужно плееру.
struct Resolved: Identifiable {
    let id = UUID()
    let label: String
    let url: URL
    let chapters: [PublicConfig.Chapter]
    let durationMs: Int?
    let live: Bool
}

enum StreamerError: LocalizedError {
    case http(Int, String)
    case noSource(String)

    var errorDescription: String? {
        switch self {
        case .http(let code, let path): return "HTTP \(code) на \(path)"
        case .noSource(let why): return why
        }
    }
}

enum StreamerAPI {
    /// Конфиг берём заново перед каждым запуском: у токена в адресе есть срок.
    static func resolve(_ item: TestItem, packaging: Packaging) async throws -> Resolved {
        switch item.kind {
        case .media:
            let cfg = try await fetch("/public/\(item.code)")
            return try make(cfg, item: item, packaging: packaging, live: false)
        case .playlist:
            let pl = try await fetch("/public/pl/\(item.code)")
            guard let first = pl.items?.first(where: { $0.locked != true }) else {
                throw StreamerError.noSource("в плейлисте нет доступных элементов")
            }
            var path = "/public/pl/\(item.code)/item/\(first.code)"
            if let t = pl.token { path += "?t=\(t)" }
            let cfg = try await fetch(path)
            return try make(cfg, item: item, packaging: packaging, live: false)
        case .channel:
            let cfg = try await fetch("/public/ch/\(item.code)")
            guard cfg.state == "ON" else { throw StreamerError.noSource("канал не вещает: \(cfg.state ?? "—")") }
            return try make(cfg, item: item, packaging: packaging, live: true)
        }
    }

    private static func make(_ cfg: PublicConfig, item: TestItem, packaging: Packaging, live: Bool) throws -> Resolved {
        let s = cfg.sources
        let raw = packaging == .mp4 ? (s?.hls?.mp4 ?? s?.mp4) : (s?.hls?.ts ?? s?.ts)
        guard let raw, let url = URL(string: raw) else {
            throw StreamerError.noSource("в конфиге нет источника \(packaging.rawValue)")
        }
        let label = "\(item.kind.rawValue) \(item.code) \(packaging.rawValue.uppercased()) «\(cfg.title ?? "")»"
            + " encrypted=\(cfg.encrypted.map { String($0) } ?? "—")"
        return Resolved(label: label, url: url, chapters: cfg.chapters ?? [],
                        durationMs: cfg.durationMs, live: live)
    }

    private static func fetch(_ path: String) async throws -> PublicConfig {
        let url = URL(string: Config.streamer.absoluteString + path)!
        var req = URLRequest(url: url)
        req.setValue(Locale.preferredLanguages.first ?? "ru", forHTTPHeaderField: "Accept-Language")
        let (data, resp) = try await URLSession.shared.data(for: req)
        let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
        let bare = path.split(separator: "?").first.map(String.init) ?? path
        guard code == 200 else { throw StreamerError.http(code, bare) }
        return try JSONDecoder().decode(PublicConfig.self, from: data)
    }
}
