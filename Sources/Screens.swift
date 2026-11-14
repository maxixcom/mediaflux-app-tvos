import CoreImage.CIFilterBuiltins
import SwiftUI

@main
struct DodocastTVApp: App {
    init() {
        // Построчный вывод: журнал читается из консоли simctl / devicectl по мере работы.
        setvbuf(stdout, nil, _IOLBF, 0)
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        Log.line("старт приложения \(v), установка \(Keychain.installationId)")
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                StreamsView().tabItem { Text("Потоки") }
                LoginView().tabItem { Text("Вход") }
            }
        }
    }
}

struct StreamsView: View {
    @State private var playing: Resolved?
    @State private var error: String?
    @State private var busy = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(Config.items) { item in
                    Section {
                        ForEach(Packaging.allCases, id: \.self) { p in
                            Button("Играть \(p.rawValue.uppercased())") { open(item, p) }
                                .disabled(busy)
                        }
                    } header: {
                        Text("\(item.kind.rawValue) \(item.code) — \(item.note)")
                    }
                }
                if let error {
                    Text(error).foregroundStyle(.red)
                }
            }
            .navigationTitle("Потоки — tst")
        }
        .task {
            if let (item, p) = Scenario.autoplay {
                Log.line("сценарий: автозапуск \(item.id) \(p.rawValue)")
                open(item, p)
            }
        }
        .fullScreenCover(item: $playing) { r in
            PlayerScreen(resolved: r).ignoresSafeArea()
        }
    }

    private func open(_ item: TestItem, _ p: Packaging) {
        busy = true
        error = nil
        Task {
            defer { busy = false }
            do {
                playing = try await StreamerAPI.resolve(item, packaging: p)
            } catch {
                self.error = "\(item.code) \(p.rawValue): \(error.localizedDescription)"
                Log.line("конфиг: ОТКАЗ \(self.error ?? "")")
            }
        }
    }
}

struct LoginView: View {
    @StateObject private var login = DeviceLogin()

    var body: some View {
        VStack(spacing: 40) {
            switch login.phase {
            case .idle:
                Button("Войти по коду") { login.start() }
            case let .waiting(code, uri, complete, expires):
                HStack(alignment: .center, spacing: 80) {
                    QRCode(text: complete).frame(width: 400, height: 400)
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Наведите камеру телефона на код или откройте").font(.title3)
                        Text(uri).font(.callout).foregroundStyle(.secondary)
                        Text(code).font(.system(size: 96, weight: .bold, design: .monospaced))
                        Text("Код действует до \(expires.formatted(date: .omitted, time: .shortened))")
                            .font(.callout).foregroundStyle(.secondary)
                        Button("Отмена") { login.cancel() }
                    }
                }
            case .signedIn:
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(login.claims, id: \.self) { Text($0).font(.callout.monospaced()) }
                }
                HStack(spacing: 40) {
                    Button("Обновить") { Task { await login.refresh() } }
                    Button("Отозвать") { Task { await login.revoke() } }
                }
            case let .failed(message):
                Text(message).foregroundStyle(.red)
                Button("Войти заново") { login.start() }
            }
            Text("установка \(Keychain.installationId) · \(Config.issuer.host ?? "")")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(80)
    }
}

/// QR из `verification_uri_complete`: телефон сразу открывает вход с подставленным кодом.
struct QRCode: View {
    let text: String

    var body: some View {
        if let image = Self.render(text) {
            Image(uiImage: image).interpolation(.none).resizable().scaledToFit()
                .padding(16).background(Color.white)
        } else {
            Text("QR не построился")
        }
    }

    private static func render(_ text: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let out = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 12, y: 12)),
              let cg = CIContext().createCGImage(out, from: out.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}
