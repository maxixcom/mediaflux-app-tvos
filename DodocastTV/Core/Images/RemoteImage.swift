import SwiftUI
import UIKit

/// Картинки (обложки) — со своим кэшем, отдельным от `URLCache.shared`: при смене сервера его чистим целиком
/// (APPS.md §5.1). Адреса ведут на стример, мимо app-api; обложки открыты по коду и кешируются CDN.
actor ImageLoader {
    static let shared = ImageLoader()

    private let cache = URLCache(memoryCapacity: 64 << 20, diskCapacity: 256 << 20, directory: ImageLoader.directory)
    private let session: URLSession
    private var memory: [URL: UIImage] = [:]
    private var inFlight: [URL: Task<UIImage?, Never>] = [:]

    private init() {
        let config = URLSessionConfiguration.default
        config.urlCache = cache
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.timeoutIntervalForRequest = 20
        session = URLSession(configuration: config)
    }

    private static var directory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0].appending(path: "images")
    }

    func image(_ url: URL) async -> UIImage? {
        if let img = memory[url] { return img }
        if let task = inFlight[url] { return await task.value }
        let session = self.session
        let task = Task<UIImage?, Never> {
            guard let (data, response) = try? await session.data(from: url),
                  (response as? HTTPURLResponse)?.statusCode == 200 else { return nil }
            return UIImage(data: data)
        }
        inFlight[url] = task
        let img = await task.value
        inFlight[url] = nil
        if let img {
            if memory.count > 400 { memory.removeAll() }
            memory[url] = img
        }
        return img
    }

    /// Смена сервера: картинки прежнего сервера больше не нужны.
    func clear() {
        memory.removeAll()
        cache.removeAllCachedResponses()
    }
}

/// Обложка 16:9 с заглушкой, пока грузится или если её нет.
struct RemoteImage: View {
    let url: URL?
    var placeholder: String = "film"
    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                LinearGradient(colors: [Color(white: 0.22), Color(white: 0.12)], startPoint: .topLeading,
                               endPoint: .bottomTrailing)
                Image(systemName: placeholder).font(.system(size: 48)).foregroundStyle(.secondary)
            }
        }
        .task(id: url) {
            image = nil
            if let url { image = await ImageLoader.shared.image(url) }
        }
    }
}
