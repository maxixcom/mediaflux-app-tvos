import Foundation

/// Токены одного сервера. Refresh (офлайн) — в Keychain под ключом сервера, access — только в памяти.
///
/// - Access обновляется заранее, за 30 с до срока, и по требованию после 401.
/// - Одновременные запросы ждут одно обновление, а не запускают своё.
/// - Отказ Keycloak в обновлении (`SIGNED_OUT`) стирает refresh: дальше — только новый вход.
actor TokenStore {
    let oidc: OIDCClient
    private let account: String
    private var endpoints: OIDCEndpoints?
    private var access: String?
    private var accessExpires = Date.distantPast
    private var refreshing: Task<String, any Error>?

    init(oidc: OIDCClient, serverKey: String) {
        self.oidc = oidc
        self.account = "refresh:\(serverKey)"
    }

    nonisolated var hasRefreshToken: Bool { Keychain.read(account) != nil }

    func endpoints() async throws -> OIDCEndpoints {
        if let endpoints { return endpoints }
        let ep = try await oidc.discover()
        endpoints = ep
        return ep
    }

    func save(_ tokens: TokenSet) {
        Keychain.write(account, tokens.refresh)
        access = tokens.access
        accessExpires = tokens.accessExpires
    }

    func accessToken(forceRefresh: Bool = false) async throws -> String {
        if !forceRefresh, let access, accessExpires.timeIntervalSinceNow > 30 { return access }
        if let refreshing { return try await refreshing.value }
        let task = Task<String, any Error> {
            guard let rt = Keychain.read(account) else { throw AppError(.signedOut) }
            do {
                let tokens = try await oidc.refresh(try await endpoints(), refreshToken: rt)
                save(tokens)
                return tokens.access
            } catch let e as AppError where e.is(.signedOut) {
                Keychain.delete(account)
                access = nil
                throw e
            }
        }
        refreshing = task
        defer { refreshing = nil }
        return try await task.value
    }

    /// Выход: отозвать офлайн-сессию у Keycloak (если он отвечает) и забыть токены.
    func signOut(revoke: Bool) async {
        if revoke, let rt = Keychain.read(account), let ep = try? await endpoints() {
            await oidc.revoke(ep, refreshToken: rt)
        }
        Keychain.delete(account)
        access = nil
        accessExpires = .distantPast
    }
}
