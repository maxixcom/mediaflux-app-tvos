import SwiftUI

@main
struct DodocastTVApp: App {
    @State private var app = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(app)
                .task {
                    Log.line("старт приложения \(AppVersion.current), установка \(Keychain.installationId)")
                    await app.start()
                }
        }
    }
}

/// Экран по состоянию приложения; метка стенда — поверх всего, кроме прода (APPS.md §5.1).
struct RootView: View {
    @Environment(AppModel.self) private var app

    var body: some View {
        ZStack(alignment: .topTrailing) {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if let stand = app.standLabel {
                StandLabel(stand: stand)
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch app.screen {
        case .starting:
            ProgressView()
        case .pickServer:
            ServerPickerView()
        case let .unavailable(error):
            ServerUnavailableView(error: error)
        case let .incompatible(minimum):
            IncompatibleView(minimum: minimum)
        case .login:
            LoginView()
        case let .problem(error):
            ProblemView(error: error)
        case let .deviceLimit(error):
            DeviceLimitView(error: error)
        case .home:
            HomeView()
        }
    }
}

/// Метка стенда: «tst» в углу экрана, чтобы не забыться и не отправить тестовое в рабочие данные.
struct StandLabel: View {
    let stand: String

    var body: some View {
        Text(stand.uppercased())
            .font(.caption.weight(.bold))
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(.orange.opacity(0.85), in: Capsule())
            .foregroundStyle(.black)
            .padding(.top, 24)
            .padding(.trailing, 48)
            .accessibilityLabel(Text("Стенд \(stand)"))
    }
}

/// Шапка экранов без каталога: логотип и заголовок.
struct BrandHeader: View {
    let title: LocalizedStringKey

    var body: some View {
        VStack(spacing: 24) {
            Image(Brand.logo)
                .resizable()
                .scaledToFit()
                .frame(height: 64)
            Text(title)
                .font(.title2.weight(.semibold))
        }
    }
}
