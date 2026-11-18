import SwiftUI

/// Выбор сервера (APPS.md §5.1): готовый список и «Другой адрес…». В сборке для App Store сюда не попасть.
struct ServerPickerView: View {
    @Environment(AppModel.self) private var app
    @State private var custom = ""
    @State private var customError: LocalizedStringKey?

    var body: some View {
        VStack(spacing: 48) {
            BrandHeader(title: "Выберите сервер")
            VStack(spacing: 20) {
                ForEach(Brand.servers) { entry in
                    Button {
                        Task { await app.choose(entry) }
                    } label: {
                        HStack {
                            Text(entry.title).font(.headline)
                            Spacer()
                            Text(entry.url.host() ?? "").foregroundStyle(.secondary)
                            if app.server == entry {
                                Image(systemName: "checkmark")
                            }
                        }
                        .frame(width: 900)
                    }
                }
                TextField("Другой адрес…", text: $custom)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .frame(width: 940)
                    .onSubmit(chooseCustom)
                if let customError {
                    Text(customError).foregroundStyle(.red)
                }
            }
        }
    }

    private func chooseCustom() {
        let text = custom.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        let withScheme = text.contains("://") ? text : "https://\(text)"
        guard let url = URL(string: withScheme), url.host() != nil else {
            customError = "Не похоже на адрес сервера"
            return
        }
        customError = nil
        Task { await app.choose(.custom(url)) }
    }
}

/// Сервер не отвечает (tst ночью выключен, MF-60): не зависать, а предложить повтор или другой сервер.
struct ServerUnavailableView: View {
    @Environment(AppModel.self) private var app
    let error: AppError

    var body: some View {
        VStack(spacing: 40) {
            BrandHeader(title: "Сервер недоступен")
            Text(error.message)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 1100)
            if let server = app.server {
                Text(server.url.absoluteString).foregroundStyle(.secondary)
            }
            HStack(spacing: 40) {
                Button("Повторить") { Task { await app.retry() } }
                if Brand.serverChoiceAllowed {
                    Button("Выбрать сервер") { app.pickServer() }
                }
            }
        }
    }
}

/// Версия приложения ниже минимальной для сервера (сведения о сервере, §5.1).
struct IncompatibleView: View {
    @Environment(AppModel.self) private var app
    let minimum: String

    var body: some View {
        VStack(spacing: 40) {
            BrandHeader(title: "Нужно обновить приложение")
            Text(AppError(.incompatibleVersion).message)
            Text("Нужна версия \(minimum) или новее, установлена \(AppVersion.current).")
                .foregroundStyle(.secondary)
            if Brand.serverChoiceAllowed {
                Button("Выбрать сервер") { app.pickServer() }
            }
        }
    }
}

/// Отказ, после которого продолжать нечем: аккаунт не готов, заблокирован, клиент не разрешён, прочее.
struct ProblemView: View {
    @Environment(AppModel.self) private var app
    let error: AppError

    var body: some View {
        VStack(spacing: 40) {
            BrandHeader(title: "Не получилось")
            Text(error.message)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 1100)
            HStack(spacing: 40) {
                Button("Повторить") { Task { await app.retry() } }
                Button("Выйти") { Task { await app.signOut() } }
                if Brand.serverChoiceAllowed {
                    Button("Выбрать сервер") { app.pickServer() }
                }
            }
        }
    }
}
