import Foundation

/// Сервер в списке выбора (APPS.md §5.1): адрес бэкенда приложений. Всё остальное — Keycloak, клиент, адрес
/// GraphQL, стенд — приложение узнаёт из сведений о сервере.
struct ServerEntry: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let title: String
    let url: URL

    /// Сервер, введённый руками («Другой адрес…»).
    static func custom(_ url: URL) -> ServerEntry {
        ServerEntry(id: "custom:\(url.absoluteString)", title: url.host() ?? url.absoluteString, url: url)
    }

    /// Ключ сервера для Keychain и кэшей: токены разных серверов не пересекаются.
    var key: String { url.host().map { "\($0):\(url.port ?? 0)" } ?? url.absoluteString }
}

/// Адрес, введённый руками («Другой адрес…»). Без схемы: стенды — `https://`, а локальная среда разработчика (IP,
/// `localhost`, `*.local`) — `http://`: TLS там нет. Порт — как ввели (app-api локально — 17091).
enum ServerAddress {
    static func url(from text: String) -> URL? {
        let text = text.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }
        if text.contains("://") {
            guard let url = URL(string: text), url.host() != nil else { return nil }
            return url
        }
        guard let probe = URL(string: "http://\(text)"), let host = probe.host() else { return nil }
        return isLocal(host) ? probe : URL(string: "https://\(text)")
    }

    static func isLocal(_ host: String) -> Bool {
        host == "localhost" || host.hasSuffix(".local")
            || host.split(separator: ".").count == 4 && host.split(separator: ".").allSatisfy { UInt8($0) != nil }
    }
}

/// Сведения о сервере — `GET /server-info?platform=tvos` (app-api, MF-88).
struct ServerInfo: Decodable, Equatable, Sendable {
    let stand: String
    let production: Bool
    let issuer: URL
    let clientId: String
    let graphqlUrl: URL
    let minAppVersion: String?
}

/// Выбранный сервер переживает перезапуск; пусто — показываем выбор.
enum ServerStore {
    private static let key = "server.selected"

    static var selected: ServerEntry? {
        get {
            UserDefaults.standard.data(forKey: key).flatMap { try? JSONDecoder().decode(ServerEntry.self, from: $0) }
        }
        set {
            if let newValue, let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}

/// Запрос сведений о сервере. Тайм-аут короткий: tst ночью выключен (MF-60), и ждать минуту нельзя.
enum ServerInfoClient {
    static let timeout: TimeInterval = 10

    static func fetch(_ server: ServerEntry, session: URLSession = .shared) async throws -> ServerInfo {
        var comps = URLComponents(url: server.url.appending(path: "server-info"), resolvingAgainstBaseURL: false)!
        comps.queryItems = [URLQueryItem(name: "platform", value: "tvos")]
        var request = URLRequest(url: comps.url!, timeoutInterval: timeout)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            Log.line("сервер \(server.url.host() ?? ""): недоступен — \(error.localizedDescription)")
            throw AppError(.serverUnavailable)
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            if let body = try? JSONDecoder().decode(ErrorBody.self, from: data) {
                throw AppError(code: body.code, params: body.params ?? [:])
            }
            Log.line("сервер \(server.url.host() ?? ""): HTTP \(status) на /server-info")
            throw AppError(.serverUnavailable)
        }
        do {
            return try JSONDecoder().decode(ServerInfo.self, from: data)
        } catch {
            Log.line("сервер \(server.url.host() ?? ""): ответ /server-info не разобран — \(error)")
            throw AppError(.serverUnavailable)
        }
    }

    private struct ErrorBody: Decodable {
        let code: String
        let params: [String: String]?
    }
}

/// Версия приложения и сравнение с минимальной версией сервера (APPS.md §5.1).
enum AppVersion {
    static var current: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    /// `true`, если версия `version` ниже `minimum`. Сравнение по числам через точку: 0.10 > 0.9.
    static func isBelow(_ version: String, minimum: String) -> Bool {
        let a = parts(version), b = parts(minimum)
        for i in 0..<max(a.count, b.count) {
            let x = i < a.count ? a[i] : 0, y = i < b.count ? b[i] : 0
            if x != y { return x < y }
        }
        return false
    }

    private static func parts(_ v: String) -> [Int] {
        v.split(separator: ".").map { Int($0.prefix { $0.isNumber }) ?? 0 }
    }
}
