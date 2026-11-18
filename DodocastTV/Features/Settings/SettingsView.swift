import SwiftUI

/// Настройки. В шаге 3.2 — аккаунт, сервер, выход; имя устройства и список устройств — шаг 3.4.
struct SettingsView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        List {
            Section("Аккаунт") {
                if let account = app.account {
                    LabeledContent("Имя", value: account.name ?? "—")
                    LabeledContent("Почта", value: account.email ?? "—")
                    LabeledContent("Устройство", value: account.deviceName ?? "—")
                }
            }
            Section("Сервер") {
                if let server = app.server {
                    LabeledContent("Адрес", value: server.url.host() ?? server.url.absoluteString)
                }
                if let stand = app.standLabel {
                    LabeledContent("Стенд", value: stand)
                }
                if Brand.serverChoiceAllowed {
                    Button("Сменить сервер") { app.pickServer() }
                }
            }
            Section {
                Button("Выйти", role: .destructive) { Task { await app.signOut() } }
                LabeledContent("Версия приложения", value: AppVersion.current)
            }
        }
        .frame(maxWidth: 1200)
    }
}
