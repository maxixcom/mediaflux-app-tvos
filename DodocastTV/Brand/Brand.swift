import SwiftUI

/// Бренд — единственное место, где клиент знает своё имя (решение 18.11.2026, MF-90).
///
/// Код приложения бренда по имени не знает: имя, логотип, цвет и серверы берёт отсюда. Второй продукт на той же
/// платформе — вторая цель со своим `Brand` (или отдельный репозиторий с общим ядром — APPS.md).
/// Имя на экране устройства и bundle id — в project.yml, иконка и логотип — в `Brand/Assets.xcassets`.
enum Brand {
    static let name = "dodocast"

    /// Логотип для тёмного фона (`Brand/Assets.xcassets/Logo`).
    static let logo = "Logo"

    /// Акцентный цвет бренда — `AccentColor` того же каталога (полоса просмотренного, отметки).
    static let accent = Color("AccentColor")

    /// Готовый список серверов (APPS.md §5.1). Прод — первым: в сборке для App Store выбор скрыт и остаётся он.
    static let servers: [ServerEntry] = [
        ServerEntry(id: "dodocast", title: "dodocast", url: URL(string: "https://app.dodocast.com")!),
        ServerEntry(id: "tst", title: "tst", url: URL(string: "https://app.tst.media-flux.ru")!)
    ]

    static var production: ServerEntry { servers[0] }

    /// Выбор сервера доступен везде, кроме сборки для App Store (флаг `APP_STORE`).
    static var serverChoiceAllowed: Bool {
        #if APP_STORE
        false
        #else
        true
        #endif
    }
}
