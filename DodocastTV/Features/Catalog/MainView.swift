import SwiftUI

/// Вошли и устройство подключено: вкладки сверху, как у штатных приложений tvOS.
struct MainView: View {
    @State private var homePath = Route.fromLaunchArguments.map { [$0] } ?? []

    var body: some View {
        // tvOS 17: вкладки старым API (`tabItem`), `Tab` — только с tvOS 18.
        TabView {
            NavigationStack(path: $homePath) { HomeView().catalogDestinations() }
                .tabItem { Label("Главная", systemImage: "house") }
            NavigationStack { LibraryIndexView().catalogDestinations() }
                .tabItem { Label("Медиатека", systemImage: "square.stack") }
            NavigationStack { SettingsView() }
                .tabItem { Label("Настройки", systemImage: "gearshape") }
        }
    }
}

extension Route {
    /// Сразу открыть экран — для проверок без пульта: `-route media:846`, `library:43`, `playlist:7`.
    static var fromLaunchArguments: Route? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-route"), i + 1 < args.count else { return nil }
        let parts = args[i + 1].split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        switch parts[0] {
        case "media": return .media(parts[1])
        case "library": return .library(LibraryRef(id: parts[1], title: "", itemCount: 0))
        case "playlist": return .playlist(parts[1])
        default: return nil
        }
    }
}

extension View {
    /// Экраны, на которые ведут карточки, — одинаково во всех вкладках.
    func catalogDestinations() -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case let .media(id): MediaDetailView(id: id)
            case let .library(ref): LibraryView(ref: ref)
            case let .playlist(id): PlaylistView(id: id)
            case let .channel(item): ChannelView(item: item)
            }
        }
    }
}

/// Загрузка экрана каталога: пока грузится — индикатор, ошибка — фраза с повтором; ошибки входа уходят в `AppModel`.
struct Loadable<Value, Content: View>: View {
    @Environment(AppModel.self) private var app
    let load: (Catalog) async throws -> Value
    @ViewBuilder let content: (Value) -> Content
    /// Перезагружать при каждом возврате на экран (ленты, избранное после карточки).
    var reloadOnAppear = false

    @State private var value: Value?
    @State private var error: AppError?

    var body: some View {
        Group {
            if let value {
                content(value)
            } else if let error {
                VStack(spacing: 32) {
                    Text(error.message).multilineTextAlignment(.center).frame(maxWidth: 1100)
                    Button("Повторить") { Task { await run() } }
                }
            } else {
                ProgressView()
            }
        }
        .task { await run() }
        .onAppear {
            if reloadOnAppear, value != nil { Task { await run() } }
        }
    }

    private func run() async {
        guard let catalog = app.catalog else { return }
        do {
            value = try await load(catalog)
            error = nil
        } catch is CancellationError {
        } catch {
            let e = AppError.from(error)
            if e.needsSignIn || e.is(.serverUnavailable) || e.is(.network) && value == nil {
                await app.handle(e)
            } else {
                self.error = e
            }
        }
    }
}
