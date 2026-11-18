import Foundation

/// Адреса Keycloak из его штатного описания (`.well-known/openid-configuration`): в приложении ни одного адреса
/// Keycloak не зашито, issuer приходит в сведениях о сервере (APPS.md §5.1).
struct OIDCEndpoints: Sendable {
    let device: URL
    let token: URL
    let revoke: URL
}

/// Код входа на экран телевизора (RFC 8628).
struct DeviceCode: Sendable, Equatable {
    let deviceCode: String
    let userCode: String
    let verificationURI: String
    /// Ссылка с подставленным кодом — она же QR: телефон сразу открывает вход.
    let verificationURIComplete: String
    let expires: Date
    let interval: Int
}

struct TokenSet: Sendable {
    let access: String
    let accessExpires: Date
    let refresh: String
}

/// Вход по коду, обновление и отзыв — протокол Keycloak без состояния. Состояние держит `TokenStore`.
struct OIDCClient: Sendable {
    let issuer: URL
    let clientId: String
    var session: URLSession = .shared

    enum PollResult: Sendable {
        case pending
        case slowDown
        case tokens(TokenSet)
    }

    func discover() async throws -> OIDCEndpoints {
        var request = URLRequest(url: issuer.appending(path: ".well-known/openid-configuration"), timeoutInterval: 10)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, _) = try await network { try await session.data(for: request) }
        let d = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        guard let device = (d["device_authorization_endpoint"] as? String).flatMap(URL.init(string:)),
              let token = (d["token_endpoint"] as? String).flatMap(URL.init(string:)),
              let revoke = (d["revocation_endpoint"] as? String).flatMap(URL.init(string:)) else {
            Log.line("вход: в описании Keycloak нет адресов входа по коду")
            throw AppError(.serverUnavailable)
        }
        return OIDCEndpoints(device: device, token: token, revoke: revoke)
    }

    /// Новый код входа. `offline_access` обязателен: иначе телевизор выйдет вместе с обычной сессией (APPS.md §5).
    func startDeviceLogin(_ ep: OIDCEndpoints) async throws -> DeviceCode {
        let (status, d) = try await post(ep.device, ["client_id": clientId, "scope": "openid offline_access"])
        guard status == 200, let deviceCode = d["device_code"] as? String, let userCode = d["user_code"] as? String
        else {
            Log.line("вход: код устройства — HTTP \(status) \(d["error"] ?? "")")
            throw AppError(status == 401 || status == 400 ? .clientNotAllowed : .serverUnavailable)
        }
        return DeviceCode(
            deviceCode: deviceCode,
            userCode: userCode,
            verificationURI: d["verification_uri"] as? String ?? "",
            verificationURIComplete: d["verification_uri_complete"] as? String ?? "",
            expires: Date().addingTimeInterval(d["expires_in"] as? Double ?? 600),
            interval: d["interval"] as? Int ?? 5
        )
    }

    func poll(_ ep: OIDCEndpoints, _ code: DeviceCode) async throws -> PollResult {
        let (status, d) = try await post(ep.token, [
            "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
            "device_code": code.deviceCode,
            "client_id": clientId
        ])
        if status == 200 { return .tokens(try tokens(d)) }
        switch d["error"] as? String {
        case "authorization_pending": return .pending
        case "slow_down": return .slowDown
        case "expired_token": throw AppError(.loginExpired)
        case "access_denied": throw AppError(.loginDenied)
        default:
            Log.line("вход: опрос — HTTP \(status) \(d["error"] ?? "")")
            throw AppError(.serverUnavailable)
        }
    }

    /// Обновление по офлайн-токену. Отказ Keycloak (`invalid_grant`: сессия отозвана или истекла) — нужен новый вход.
    func refresh(_ ep: OIDCEndpoints, refreshToken: String) async throws -> TokenSet {
        let (status, d) = try await post(ep.token, [
            "grant_type": "refresh_token", "refresh_token": refreshToken, "client_id": clientId
        ])
        if status == 200 { return try tokens(d) }
        if status == 400 || status == 401 {
            Log.line("вход: обновление отклонено — \(d["error"] ?? status)")
            throw AppError(.signedOut)
        }
        throw AppError(.serverUnavailable)
    }

    /// Отзыв офлайн-сессии устройством (`/revoke`). Ошибки не бросает: недоступный Keycloak — просто забыть токен.
    func revoke(_ ep: OIDCEndpoints, refreshToken: String) async {
        let status = (try? await post(ep.revoke, [
            "token": refreshToken, "token_type_hint": "refresh_token", "client_id": clientId
        ]))?.0 ?? 0
        Log.line("вход: /revoke → HTTP \(status)")
    }

    private func tokens(_ d: [String: Any]) throws -> TokenSet {
        guard let access = d["access_token"] as? String, let refresh = d["refresh_token"] as? String else {
            throw AppError(.serverUnavailable)
        }
        let expiresIn = d["expires_in"] as? Double ?? 60
        return TokenSet(access: access, accessExpires: Date().addingTimeInterval(expiresIn), refresh: refresh)
    }

    private func post(_ url: URL, _ form: [String: String]) async throws -> (Int, [String: Any]) {
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var comps = URLComponents()
        comps.queryItems = form.map { URLQueryItem(name: $0.key, value: $0.value) }
        request.httpBody = comps.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B").data(using: .utf8)
        let (data, response) = try await network { try await session.data(for: request) }
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        return ((response as? HTTPURLResponse)?.statusCode ?? 0, json)
    }

    private func network<T>(_ body: () async throws -> T) async throws -> T {
        do { return try await body() } catch { throw AppError(.network) }
    }
}
