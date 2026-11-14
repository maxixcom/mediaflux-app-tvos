import Foundation

/// Вход по коду (RFC 8628). Адреса Keycloak берутся из его описания по issuer — заготовка выбора
/// сервера (APPS.md §5.1). Токены на экран и в журнал не выводятся, только утверждения.
@MainActor
final class DeviceLogin: ObservableObject {
    enum Phase {
        case idle
        case waiting(userCode: String, uri: String, uriComplete: String, expires: Date)
        case signedIn
        case failed(String)
    }

    @Published var phase: Phase = .idle
    @Published var claims: [String] = []

    private struct Endpoints {
        let device: URL
        let token: URL
        let revoke: URL
    }

    private var endpoints: Endpoints?
    private var polling: Task<Void, Never>?

    init() {
        if Keychain.read("refresh") != nil {
            phase = .signedIn
            claims = ["в Keychain есть refresh-токен — нажмите «Обновить»"]
            Log.line("вход: refresh-токен из Keychain пережил перезапуск")
        }
    }

    func start() {
        polling?.cancel()
        polling = Task {
            do {
                let ep = try await discover()
                let (code, d) = try await post(ep.device, ["client_id": Config.clientId, "scope": "openid offline_access"])
                guard code == 200, let deviceCode = d["device_code"] as? String,
                      let userCode = d["user_code"] as? String else {
                    phase = .failed("код устройства: HTTP \(code) \(d["error"] ?? "")"); return
                }
                let expires = Date().addingTimeInterval(d["expires_in"] as? Double ?? 600)
                phase = .waiting(userCode: userCode,
                                 uri: d["verification_uri"] as? String ?? "",
                                 uriComplete: d["verification_uri_complete"] as? String ?? "",
                                 expires: expires)
                Log.line("вход: код \(userCode), ждём подтверждения")
                var interval = UInt64(d["interval"] as? Int ?? 5)
                while Date() < expires, !Task.isCancelled {
                    try await Task.sleep(nanoseconds: interval * 1_000_000_000)
                    let (c, t) = try await post(ep.token, [
                        "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                        "device_code": deviceCode, "client_id": Config.clientId])
                    if c == 200 { accept(t, title: "вход выполнен"); return }
                    switch t["error"] as? String {
                    case "authorization_pending": continue
                    case "slow_down": interval += 5
                    default: phase = .failed("опрос: HTTP \(c) \(t["error"] ?? "")"); return
                    }
                }
                if !Task.isCancelled { phase = .failed("код истёк") }
            } catch {
                phase = .failed(error.localizedDescription)
            }
        }
    }

    func cancel() {
        polling?.cancel()
        phase = .idle
    }

    func refresh() async {
        guard let rt = Keychain.read("refresh") else { phase = .idle; return }
        do {
            let ep = try await discover()
            let (c, t) = try await post(ep.token, ["grant_type": "refresh_token", "refresh_token": rt,
                                                   "client_id": Config.clientId])
            if c == 200 {
                accept(t, title: "обновлено")
            } else {
                Log.line("вход: обновление отклонено HTTP \(c) \(t["error"] ?? "") \(t["error_description"] ?? "")")
                Keychain.delete("refresh")
                phase = .failed("обновление: \(t["error"] ?? c) — нужен новый вход")
            }
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func revoke() async {
        guard let rt = Keychain.read("refresh") else { phase = .idle; return }
        if let ep = try? await discover() {
            let (c, _) = (try? await post(ep.revoke, ["token": rt, "token_type_hint": "refresh_token",
                                                      "client_id": Config.clientId])) ?? (0, [:])
            Log.line("вход: /revoke → HTTP \(c)")
        }
        Keychain.delete("refresh")
        claims = []
        phase = .idle
    }

    private func accept(_ t: [String: Any], title: String) {
        guard let access = t["access_token"] as? String, let refresh = t["refresh_token"] as? String else {
            phase = .failed("в ответе нет токенов"); return
        }
        let previous = Keychain.read("refresh")
        Keychain.write("refresh", refresh)
        let a = Self.claims(of: access)
        let r = Self.claims(of: refresh)
        let exp = (a["exp"] as? Double).map { Date(timeIntervalSince1970: $0).formatted(date: .omitted, time: .standard) } ?? "—"
        claims = [
            "azp: \(a["azp"] ?? "—")",
            "sub: \(a["sub"] ?? "—")",
            "sid: \(a["sid"] ?? "—")",
            "scope: \(a["scope"] ?? "—")",
            "access до: \(exp)",
            "refresh: typ=\(r["typ"] ?? "—"), \(previous == nil ? "первый" : (previous == refresh ? "тот же" : "новый"))"
        ]
        phase = .signedIn
        Log.line("вход: \(title); " + claims.joined(separator: "; "))
    }

    private func discover() async throws -> Endpoints {
        if let endpoints { return endpoints }
        let url = Config.issuer.appendingPathComponent(".well-known/openid-configuration")
        let (data, _) = try await URLSession.shared.data(from: url)
        let d = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        guard let dev = (d["device_authorization_endpoint"] as? String).flatMap(URL.init(string:)),
              let tok = (d["token_endpoint"] as? String).flatMap(URL.init(string:)),
              let rev = (d["revocation_endpoint"] as? String).flatMap(URL.init(string:)) else {
            throw URLError(.badServerResponse)
        }
        let ep = Endpoints(device: dev, token: tok, revoke: rev)
        endpoints = ep
        Log.line("вход: адреса Keycloak взяты из .well-known \(Config.issuer.host ?? "")")
        return ep
    }

    private func post(_ url: URL, _ form: [String: String]) async throws -> (Int, [String: Any]) {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var comps = URLComponents()
        comps.queryItems = form.map { URLQueryItem(name: $0.key, value: $0.value) }
        req.httpBody = comps.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B").data(using: .utf8)
        let (data, resp) = try await URLSession.shared.data(for: req)
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
        return ((resp as? HTTPURLResponse)?.statusCode ?? 0, json)
    }

    private static func claims(of jwt: String) -> [String: Any] {
        let parts = jwt.split(separator: ".")
        guard parts.count > 1 else { return [:] }
        var b64 = parts[1].replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        b64 += String(repeating: "=", count: (4 - b64.count % 4) % 4)
        guard let data = Data(base64Encoded: b64) else { return [:] }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] ?? [:]
    }
}
