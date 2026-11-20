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
    /// Недосланные отчёты о позиции этого сервера (§7).
    let outbox: ProgressOutbox

    var progress: ProgressSender { ProgressSender(api: api, outbox: outbox) }
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

    /// Номер версии состояния зрителя (MF-116): избранное, «просмотрено», позиция после плеера. Экраны с карточками
    /// перечитываются по его смене (`.task(id:)`), а не «при появлении»: с боковым меню при возврате из стека раздела
    /// событие появления не приходит.
    private(set) var viewerRevision = 0

    /// Своё изменение состояния зрителя — экраны с карточками перечитаются, пока человек ещё на карточке.
    func viewerChanged() { viewerRevision &+= 1 }

    /// Каталог текущего сервера; нет сессии — нет каталога.
    var catalog: Catalog? { session.map { Catalog(api: $0.api) } }

    var progressSender: ProgressSender? { session?.progress }

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
        let session = Session(server: entry, info: info, tokens: tokens, api: API(graphqlURL: info.graphqlUrl, tokens: tokens),
                              outbox: ProgressOutbox(serverKey: entry.key))
        self.session = session
        Log.line("сервер \(info.stand) (\(entry.url.host() ?? "")): прод=\(info.production), клиент \(info.clientId)")
        if tokens.hasRefreshToken {
            await resumeSession()
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

    /// Старт с сохранённым входом: устройство уже подключено и версия та же — сразу на главный экран; иначе —
    /// регистрация. Регистрацию на каждом старте не зовём: у неё лимит (5 в час на пользователя, APPS.md §10), и пара
    /// перезапусков подряд закрыла бы вход. `me` доступен и без устройства.
    private func resumeSession() async {
        guard let session else { return }
        do {
            let me = try await session.api.fetch(DCAPI.MeQuery()).me
            if let device = me.device?.fragments.deviceFields, device.appVersion == AppVersion.current {
                account = Account(name: me.name, email: me.email, deviceId: device.id, deviceName: device.name)
                Log.line("устройство уже подключено: \(device.name)")
                screen = .home
                Task { await session.progress.flush() }
                return
            }
        } catch {
            await handle(AppError.from(error))
            return
        }
        await registerDevice()
    }

    /// Регистрация устройства (§6): после входа и при новой версии приложения. Повтор для той же установки обновляет
    /// запись и слот не тратит.
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
            Task { await session.progress.flush() }
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
        await session.progress.flush()
        await session.outbox.clear()
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
        await old.progress.flush()
        await old.tokens.signOut(revoke: revoke)
        await ImageLoader.shared.clear()
        session = nil
        account = nil
        Log.line("сервер \(old.info.stand): вышли")
    }
}
