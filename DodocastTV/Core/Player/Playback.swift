import Foundation

/// Что играть и откуда начать.
struct PlayRequest: Identifiable, Hashable {
    enum Start: Hashable {
        /// С позиции, которую вернул сервер (`resumePositionMs`), а без неё — с начала.
        case resume
        case beginning
    }

    enum Target: Hashable {
        /// Медиа; `queue` — остальная очередь (подборка): после конца элемента играет следующий.
        case media(id: String, queue: [String])
        case channel(id: String)
    }

    let id = UUID()
    let target: Target
    let start: Start

    static func media(_ id: String, start: Start = .resume, queue: [String] = []) -> PlayRequest {
        PlayRequest(target: .media(id: id, queue: queue), start: start)
    }

    static func channel(_ id: String) -> PlayRequest {
        PlayRequest(target: .channel(id: id), start: .beginning)
    }
}

struct Chapter: Hashable, Sendable {
    let startMs: Int
    let title: String
}

/// Ответ «начать просмотр» (§8): адрес потока с токеном на сеанс, главы, обложка, превью, позиция возобновления.
struct PlaybackInfo: Sendable {
    let url: URL
    let expiresAt: Date?
    let title: String
    let durationMs: Int?
    let chapters: [Chapter]
    let coverURL: URL?
    let previewManifestURL: URL?
    let resumePositionMs: Int?
}

enum DateTimeFormat {
    /// `DateTime` app-api: ISO 8601 в UTC.
    static func string(_ date: Date) -> String {
        date.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: true).timeZone(separator: .omitted))
    }

    static func date(_ s: String) -> Date? {
        try? Date(s, strategy: .iso8601.year().month().day().time(includingFractionalSeconds: true))
            ?? (try? Date(s, strategy: .iso8601))
    }
}

extension Catalog {
    func playbackStart(_ target: PlayRequest.Target, mediaId: String? = nil) async throws -> PlaybackInfo {
        let input: DCAPI.PlaybackStartInput
        switch target {
        case let .media(id, _): input = DCAPI.PlaybackStartInput(mediaId: .some(mediaId ?? id))
        case let .channel(id): input = DCAPI.PlaybackStartInput(channelId: .some(id))
        }
        let p = try await api.perform(DCAPI.PlaybackStartMutation(input: input)).playbackStart
        guard let url = URL(string: p.url) else { throw AppError(.unknown) }
        return PlaybackInfo(
            url: url,
            expiresAt: DateTimeFormat.date(p.expiresAt),
            title: p.title,
            durationMs: p.durationMs,
            chapters: p.chapters.map { Chapter(startMs: $0.startMs, title: $0.title) },
            coverURL: p.coverUrl.flatMap(URL.init(string:)),
            previewManifestURL: p.previewManifestUrl.flatMap(URL.init(string:)),
            resumePositionMs: p.resumePositionMs
        )
    }
}
