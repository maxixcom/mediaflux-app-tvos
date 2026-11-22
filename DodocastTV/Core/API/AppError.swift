import Foundation

/// Ошибка по контракту платформы (ERROR_HANDLING.md): стабильный код и параметры, фразу на языке пользователя собирает
/// приложение. Коды сервера — из `extensions.code` (app-api `ErrorCodes`) и тела 403 (`{"error": …}`); свои коды
/// клиента — для того, что сервер сказать не может (нет связи, код входа истёк).
struct AppError: Error, Equatable, Sendable {
    let code: String
    let params: [String: String]

    init(code: String, params: [String: String] = [:]) {
        self.code = code
        self.params = params
    }

    init(_ code: Code, params: [String: String] = [:]) {
        self.init(code: code.rawValue, params: params)
    }

    enum Code: String {
        // Клиент
        case serverUnavailable = "SERVER_UNAVAILABLE"
        case network = "NETWORK"
        case signedOut = "SIGNED_OUT"
        case loginExpired = "LOGIN_EXPIRED"
        case loginDenied = "LOGIN_DENIED"
        case incompatibleVersion = "INCOMPATIBLE_VERSION"
        case playbackFailed = "PLAYBACK_FAILED"
        case unknown = "UNKNOWN"
        // 403 входа (app-api AppAuthenticationEntryPoint)
        case accountNotReady = "account_not_ready"
        case accountDisabled = "account_disabled"
        case clientNotAllowed = "client_not_allowed"
        // GraphQL (app-api ErrorCodes)
        case notFound = "NOT_FOUND"
        case badInput = "BAD_INPUT"
        case deviceNotRegistered = "DEVICE_NOT_REGISTERED"
        case deviceRevoked = "DEVICE_REVOKED"
        case deviceLimitReached = "DEVICE_LIMIT_REACHED"
        case deliveryBlocked = "DELIVERY_BLOCKED"
        case channelOffAir = "CHANNEL_OFF_AIR"
        case channelsNotInTariff = "CHANNELS_NOT_IN_TARIFF"
        /// Приложения закрыты тарифом (MF-91): работают только `me` и отключение устройства — экран проблемы с «Выйти».
        case appsNotInTariff = "APPS_NOT_IN_TARIFF"
        case rateLimited = "RATE_LIMITED"
        case operationNotRegistered = "OPERATION_NOT_REGISTERED"
        case serverBusy = "SERVER_BUSY"
        case platformNotSupported = "PLATFORM_NOT_SUPPORTED"
    }

    var known: Code? { Code(rawValue: code) }

    func `is`(_ c: Code) -> Bool { code == c.rawValue }

    /// Ошибка требует нового входа: токен отозван, устройство отключено.
    var needsSignIn: Bool {
        `is`(.signedOut) || `is`(.deviceRevoked) || `is`(.deviceNotRegistered)
    }

    /// Фраза для человека (ru — исходный язык, en — в `Localizable.xcstrings`).
    var message: String {
        switch known {
        case .serverUnavailable: String(localized: "Сервер не отвечает. Проверьте сеть или выберите другой сервер.")
        case .network: String(localized: "Нет связи с сервером. Проверьте подключение к сети.")
        case .signedOut: String(localized: "Вход больше не действует — войдите заново.")
        case .loginExpired: String(localized: "Код истёк. Получите новый.")
        case .loginDenied: String(localized: "Вход отклонён на телефоне.")
        case .playbackFailed: String(localized: "Не удалось воспроизвести. Попробуйте ещё раз.")
        case .incompatibleVersion, .operationNotRegistered: String(localized: "Версия приложения не подходит этому серверу.")
        case .accountNotReady:
            String(localized: "Аккаунт ещё не готов: один раз откройте личный кабинет в браузере и войдите.")
        case .accountDisabled: String(localized: "Аккаунт заблокирован. Обратитесь в поддержку.")
        case .clientNotAllowed: String(localized: "Этому приложению вход на сервер не разрешён.")
        case .notFound: String(localized: "Не найдено — возможно, материал удалён или скрыт.")
        case .badInput: String(localized: "Сервер не принял запрос.")
        case .deviceNotRegistered: String(localized: "Устройство не подключено — войдите заново.")
        case .deviceRevoked: String(localized: "Это устройство отключено — войдите заново.")
        case .deviceLimitReached:
            String(localized: "Подключено максимум устройств (\(params["limit"] ?? "—")). Отключите одно, чтобы подключить это.")
        case .deliveryBlocked:
            switch params["reason"] {
            case "SUSPENDED": String(localized: "Просмотр приостановлен: на балансе минус. Пополните баланс в личном кабинете.")
            case "TRAFFIC_LIMIT": String(localized: "Исчерпан лимит трафика тарифа.")
            default: String(localized: "Просмотр сейчас недоступен.")
            }
        case .channelOffAir: String(localized: "Канал сейчас не в эфире.")
        case .channelsNotInTariff: String(localized: "Каналы не входят в ваш тариф.")
        case .appsNotInTariff: String(localized: "Приложения не входят в ваш тариф. Условия — в личном кабинете.")
        case .rateLimited: String(localized: "Слишком много запросов. Повторите через \(params["retryAfterSeconds"] ?? "—") с.")
        case .serverBusy: String(localized: "Сервер перегружен. Повторите чуть позже.")
        case .platformNotSupported: String(localized: "Сервер не поддерживает Apple TV.")
        case .unknown, nil: String(localized: "Что-то пошло не так (\(code)).")
        }
    }

    /// Любая ошибка — в контракт: наша как есть, сеть — `NETWORK`, остальное — `UNKNOWN` (с записью в журнал).
    static func from(_ error: any Error) -> AppError {
        if let e = error as? AppError { return e }
        if error is URLError { return AppError(.network) }
        if (error as NSError).domain == NSURLErrorDomain { return AppError(.network) }
        Log.line("ошибка без кода: \(error)")
        return AppError(.unknown)
    }
}
