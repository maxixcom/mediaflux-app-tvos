import CoreImage.CIFilterBuiltins
import SwiftUI

/// Вход по коду (APPS.md §5): QR для телефона, код крупно, адрес для ручного ввода. Пароль с пульта не вводят.
struct LoginView: View {
    @Environment(AppModel.self) private var app
    @State private var login = LoginModel()

    var body: some View {
        VStack(spacing: 48) {
            BrandHeader(title: "Вход")
            switch login.phase {
            case .preparing:
                ProgressView().frame(height: 400)
            case let .waiting(code):
                HStack(alignment: .center, spacing: 80) {
                    QRCode(text: code.verificationURIComplete).frame(width: 400, height: 400)
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Наведите камеру телефона на QR-код или откройте адрес и введите код:")
                            .font(.title3)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: 900, alignment: .leading)
                        Text(code.verificationURI).font(.callout).foregroundStyle(.secondary)
                        Text(code.userCode).font(.system(size: 96, weight: .bold, design: .monospaced))
                        Text("Код действует до \(code.expires.formatted(date: .omitted, time: .shortened))")
                            .font(.callout).foregroundStyle(.secondary)
                    }
                }
            case let .failed(error):
                VStack(spacing: 32) {
                    Text(error.message).multilineTextAlignment(.center).frame(maxWidth: 1100)
                    Button("Получить новый код") { startLogin() }
                }
                .frame(height: 400)
            }
            serverLine
        }
        .onAppear(perform: startLogin)
        .onDisappear { login.stop() }
    }

    /// «Сервер: …» на экране входа — отсюда же смена сервера (§5.1).
    @ViewBuilder private var serverLine: some View {
        if Brand.serverChoiceAllowed, let server = app.server {
            Button {
                login.stop()
                app.pickServer()
            } label: {
                Text("Сервер: \(server.title) · сменить").font(.callout)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
    }

    private func startLogin() {
        guard let session = app.session else { return }
        login.start(session: session) { tokens in
            await app.signedIn(tokens)
        }
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
            Color.clear
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
