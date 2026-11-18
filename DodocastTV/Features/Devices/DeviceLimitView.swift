import SwiftUI

/// Подключено максимум устройств (APPS.md §6): лишнее отключают прямо здесь, без кабинета. Сервер пускает к этим
/// операциям и без зарегистрированного устройства.
struct DeviceLimitView: View {
    @Environment(AppModel.self) private var app
    let error: AppError
    @State private var devices: [DCAPI.DeviceFields] = []
    @State private var busy = false

    var body: some View {
        VStack(spacing: 40) {
            BrandHeader(title: "Подключено много устройств")
            Text(error.message)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 1100)
            VStack(spacing: 16) {
                ForEach(devices, id: \.id) { device in
                    HStack(spacing: 32) {
                        VStack(alignment: .leading) {
                            Text(device.name).font(.headline)
                            if let seen = device.lastSeenAt {
                                Text("Был в сети: \(seen.formattedDate)").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .frame(width: 700, alignment: .leading)
                        Button("Отключить") { revoke(device.id) }
                            .disabled(busy)
                    }
                }
            }
            Button("Выйти") { Task { await app.signOut() } }
        }
        .task { await load() }
    }

    private func load() async {
        guard let api = app.session?.api else { return }
        do {
            devices = try await api.fetch(DCAPI.DevicesQuery()).devices.map(\.fragments.deviceFields)
        } catch {
            await app.handle(AppError.from(error))
        }
    }

    private func revoke(_ id: String) {
        guard let api = app.session?.api else { return }
        busy = true
        Task {
            defer { busy = false }
            do {
                _ = try await api.perform(DCAPI.DeviceRevokeMutation(id: id))
                Log.line("устройство отключено, повторяем подключение")
                await app.registerDevice()
            } catch {
                await app.handle(AppError.from(error))
            }
        }
    }
}

extension String {
    /// Дата-время из `DateTime` сервера (ISO 8601, UTC) — в местное «18 нояб., 16:20».
    var formattedDate: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let date = iso.date(from: self) ?? ISO8601DateFormatter().date(from: self)
        return date?.formatted(date: .abbreviated, time: .shortened) ?? self
    }
}
