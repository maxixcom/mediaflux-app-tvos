import SwiftUI

/// Главный экран. В шаге 3.1 — кто вошёл и с какого устройства; ленты каталога — шаг 3.2.
struct HomeView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        VStack(spacing: 40) {
            BrandHeader(title: "Вы вошли")
            if let account = app.account {
                VStack(spacing: 12) {
                    if let name = account.name { Text(name).font(.headline) }
                    if let email = account.email { Text(email).foregroundStyle(.secondary) }
                    if let device = account.deviceName { Text("Устройство: \(device)").foregroundStyle(.secondary) }
                }
            }
            HStack(spacing: 40) {
                if Brand.serverChoiceAllowed {
                    Button("Сменить сервер") { app.pickServer() }
                }
                Button("Выйти") { Task { await app.signOut() } }
            }
        }
    }
}
