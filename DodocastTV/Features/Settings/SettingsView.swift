import SwiftUI

/// Настройки: аккаунт, это устройство (имя), подключённые устройства с «Отключить», сервер, выход, версия (§5.1, §6).
struct SettingsView: View {
    @Environment(AppModel.self) private var app
    @State private var devices: [DCAPI.DeviceFields] = []
    @State private var confirmRevoke: DCAPI.DeviceFields?
    @State private var confirmSignOut = false
    @State private var error: AppError?

    var body: some View {
        List {
            Section("Аккаунт") {
                if let account = app.account {
                    LabeledContent("Имя", value: account.name ?? "—")
                    LabeledContent("Почта", value: account.email ?? "—")
                }
            }
            Section("Это устройство") {
                NavigationLink {
                    DeviceNameEditor()
                } label: {
                    LabeledContent("Имя", value: app.account?.deviceName ?? "—")
                }
            }
            Section("Устройства") {
                ForEach(devices, id: \.id) { device in
                    if device.current {
                        LabeledContent(device.name, value: String(localized: "Это устройство"))
                    } else {
                        Button {
                            confirmRevoke = device
                        } label: {
                            LabeledContent(device.name, value: device.lastSeenAt.map { String(localized: "Был в сети: \($0.formattedDate)") } ?? "")
                        }
                    }
                }
                if let error { Text(error.message).foregroundStyle(.secondary) }
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
                Button("Выйти", role: .destructive) { confirmSignOut = true }
                LabeledContent("Версия приложения", value: AppVersion.current)
            }
        }
        .frame(maxWidth: 1200)
        .task { await loadDevices() }
        .confirmationDialog(confirmRevoke.map { String(localized: "Отключить «\($0.name)»?") } ?? "",
                            isPresented: Binding(get: { confirmRevoke != nil }, set: { if !$0 { confirmRevoke = nil } }),
                            titleVisibility: .visible) {
            Button("Отключить", role: .destructive) {
                if let device = confirmRevoke { revoke(device) }
            }
        } message: {
            Text("На том устройстве потребуется войти заново.")
        }
        .confirmationDialog("Выйти из аккаунта на этом устройстве?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Выйти", role: .destructive) { Task { await app.signOut() } }
        }
    }

    private func loadDevices() async {
        guard let api = app.session?.api else { return }
        do {
            devices = try await api.fetch(DCAPI.DevicesQuery()).devices.map(\.fragments.deviceFields)
            error = nil
        } catch is CancellationError {
        } catch {
            let e = AppError.from(error)
            if e.needsSignIn { await app.handle(e) } else { self.error = e }
        }
    }

    private func revoke(_ device: DCAPI.DeviceFields) {
        guard let api = app.session?.api else { return }
        Task {
            do {
                _ = try await api.perform(DCAPI.DeviceRevokeMutation(id: device.id))
                Log.line("устройство отключено: \(device.name)")
                await loadDevices()
            } catch {
                self.error = AppError.from(error)
            }
        }
    }
}

/// Имя этого устройства в списке устройств (`deviceRename`). tvOS имени устройства приложению не отдаёт — по
/// умолчанию в списке «Apple TV», поэтому имя стоит задать самому («Гостиная»).
private struct DeviceNameEditor: View {
    @Environment(AppModel.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var error: AppError?
    @State private var busy = false

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text("Имя устройства").font(.title2.weight(.semibold))
            TextField("Например, Гостиная", text: $name)
                .frame(maxWidth: 900)
                .onSubmit(save)
            HStack(spacing: 32) {
                Button("Сохранить", action: save).disabled(busy || name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if let error { Text(error.message).foregroundStyle(.secondary) }
            Spacer()
        }
        .padding(80)
        .onAppear { name = app.account?.deviceName ?? "" }
    }

    private func save() {
        let value = name.trimmingCharacters(in: .whitespaces)
        guard !value.isEmpty, value.count <= 100, let id = app.account?.deviceId, let api = app.session?.api else { return }
        busy = true
        Task {
            defer { busy = false }
            do {
                _ = try await api.perform(DCAPI.DeviceRenameMutation(id: id, name: value))
                await app.loadAccount()
                dismiss()
            } catch {
                self.error = AppError.from(error)
            }
        }
    }
}
