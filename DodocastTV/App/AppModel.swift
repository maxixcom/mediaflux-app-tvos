import Foundation
import Observation
import UIKit

/// Подключение к одному серверу: сведения о нём, токены и GraphQL. Сессий нескольких серверов одновременно не держим —
/// смена сервера выбрасывает эту целиком (APPS.md §5.1).
struct Session: Sendable {
    let server: ServerEntry
    let info: ServerInfo
    let tokens: TokenStore
    let api: API
}

/// Кто вошёл и с какого устройства — для экранов и настроек.
struct Account: Equatable, Sendable {
    let name: String?
    let email: String?
    let deviceId: String?
    let deviceName: String?
}

/// Корневое состояние приложения: какой экран показать и переходы между ними.
///
/// Путь: сервер → сведения о сервере (версия, стенд) → вход по коду → регистрация устройства → главный экран.
@MainActor
@Observable
final class AppModel {
    enum Screen: Equatable {
        case starting
        case pickServer
        case unavailable(AppError)
        case incompatible(minimum: String)
        case login
        case problem(AppError)
        case deviceLimit(AppError)
        case home
    }

    private(set) var screen: Screen = .starting
    private(set) var server: ServerEntry?
    private(set) var session: Session?
    private(set) var account: Account?

    /// Метка стенда на экране — для всего, кроме прода (APPS.md §5.1).
    var standLabel: String? {
        guard let info = session?.info, !info.production else { return nil }
        return info.stand
    }

    // MARK: - Сервер

    func start() async {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-server"), i + 1 < args.count, let url = URL(string: args[i + 1]) {
            ServerStore.selected = Brand.servers.first { $0.url == url } ?? .custom(url)
        }
        if !Brand.serverChoiceAllowed { ServerStore.selected = Brand.production }
        guard let selected = ServerStore.selected else {
            screen = .pickServer
            return
        }
        await connect(selected)
    }

    func pickServer() {
        guard Brand.serverChoiceAllowed else { return }
        screen = .pickServer
    }

    /// Выбор сервера в списке. Тот же — просто переподключиться; другой — выйти со старого и почистить всё.
    func choose(_ entry: ServerEntry) async {
        if let old = session, old.server != entry {
            await leave(old, revoke: true)
        }
        ServerStore.selected = entry
        await connect(entry)
    }

    func retry() async {
        guard let server else { screen = .pickServer; return }
        await connect(server)
    }

    private func connect(_ entry: ServerEntry) async {
        server = entry
        screen = .starting
        let info: ServerInfo
        do {
            info = try await ServerInfoClient.fetch(entry)
        } catch {
            screen = .unavailable(AppError.from(error))
            return
        }
        if let minimum = info.minAppVersion, AppVersion.isBelow(AppVersion.current, minimum: minimum) {
            Log.line("сервер \(info.stand): версия \(AppVersion.current) ниже \(minimum)")
            screen = .incompatible(minimum: minimum)
            return
        }
        let tokens = TokenStore(oidc: OIDCClient(issuer: info.issuer, clientId: info.clientId), serverKey: entry.key)
        let session = Session(server: entry, info: info, tokens: tokens, api: API(graphqlURL: info.graphqlUrl, tokens: tokens))
        self.session = session
        Log.line("сервер \(info.stand) (\(entry.url.host() ?? "")): прод=\(info.production), клиент \(info.clientId)")
        if tokens.hasRefreshToken {
            await registerDevice()
        } else {
            screen = .login
        }
    }

    // MARK: - Вход и устройство

    /// Код подтверждён на телефоне — запомнить токены и подключить устройство.
    func signedIn(_ tokenSet: TokenSet) async {
        guard let session else { return }
        await session.tokens.save(tokenSet)
        Log.line("вход выполнен")
        await registerDevice()
    }

    /// Регистрация устройства (§6): повтор для той же установки обновляет запись и слот не тратит, поэтому
    /// зовём её на каждом старте — заодно сервер узнаёт версию приложения.
    func registerDevice() async {
        guard let session else { return }
        let input = DCAPI.DeviceRegisterInput(
            installationId: Keychain.installationId,
            name: UIDevice.current.name,
            platform: .case(.tvos),
            appVersion: AppVersion.current
        )
        do {
            let device = try await session.api.perform(DCAPI.DeviceRegisterMutation(input: input)).deviceRegister
            Log.line("устройство подключено: \(device.fragments.deviceFields.name)")
            await loadAccount()
            screen = .home
        } catch {
            let e = AppError.from(error)
            if e.is(.deviceLimitReached) {
                screen = .deviceLimit(e)
            } else {
                await handle(e)
            }
        }
    }

    func loadAccount() async {
        guard let session else { return }
        do {
            let me = try await session.api.fetch(DCAPI.MeQuery()).me
            let device = me.device?.fragments.deviceFields
            account = Account(name: me.name, email: me.email, deviceId: device?.id, deviceName: device?.name)
        } catch {
            Log.line("me: \(AppError.from(error).code)")
        }
    }

    /// Выйти: отключить своё устройство на сервере (слот освобождается), отозвать офлайн-сессию, забыть токены.
    func signOut() async {
        guard let session else { return }
        if let id = account?.deviceId {
            _ = try? await session.api.perform(DCAPI.DeviceRevokeMutation(id: id))
        }
        await session.tokens.signOut(revoke: true)
        account = nil
        screen = .login
    }

    /// Общая реакция на ошибку, после которой экран продолжать не может.
    func handle(_ error: AppError) async {
        Log.line("ошибка: \(error.code)")
        if error.needsSignIn {
            await session?.tokens.signOut(revoke: false)
            account = nil
            screen = .login
        } else if error.is(.serverUnavailable) || error.is(.network) {
            screen = .unavailable(error)
        } else if error.is(.incompatibleVersion) || error.is(.operationNotRegistered) {
            screen = .incompatible(minimum: session?.info.minAppVersion ?? "—")
        } else {
            screen = .problem(error)
        }
    }

    /// Уйти со старого сервера (смена сервера, §5.1): дослать позицию, отозвать офлайн-токен у его Keycloak (если он
    /// отвечает), забыть токены; кэш Apollo уходит вместе с `API`. Идентификатор установки остаётся.
    private func leave(_ old: Session, revoke: Bool) async {
        await old.tokens.signOut(revoke: revoke)
        session = nil
        account = nil
        Log.line("сервер \(old.info.stand): вышли")
    }
}
