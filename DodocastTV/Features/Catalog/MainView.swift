import SwiftUI

/// Вошли и устройство подключено: разделы в боковом меню, как у приложения Apple TV (tvOS 18+).
///
/// Меню слева, при переходе в содержимое сворачивается в плашку раздела; у каждого раздела свой стек экранов.
/// «Назад» — на шаг назад, с корня раздела — открыть меню; повторный выбор раздела в меню — к его началу (поиск — к
/// строке поиска). Поиск — первым пунктом, с ролью `.search`.
struct MainView: View {
    @Environment(AppModel.self) private var app
    @State private var tab = MainTab.fromLaunchArguments ?? .home
    @State private var homePath = Route.fromLaunchArguments.map { [$0] } ?? []
    @State private var searchPath: [Route] = []
    @State private var libraryPath: [Route] = []
    @State private var autoplay = PlayRequest.fromLaunchArguments

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("Поиск", systemImage: "magnifyingglass", value: MainTab.search, role: .search) {
                NavigationStack(path: $searchPath) { SearchView(path: $searchPath).catalogDestinations() }
            }
            Tab("Главная", systemImage: "house", value: MainTab.home) {
                NavigationStack(path: $homePath) { HomeView().catalogDestinations() }
            }
            Tab("Медиатека", systemImage: "square.stack", value: MainTab.library) {
                NavigationStack(path: $libraryPath) { LibraryIndexView().catalogDestinations() }
            }
            Tab("Настройки", systemImage: "gearshape", value: MainTab.settings) {
                NavigationStack { SettingsView() }
            }
        }
        .tabViewStyle(.sidebarAdaptable)
        .sidebarHeader(name: app.account?.name)
        .fullScreenCover(item: $autoplay) { PlayerView(request: $0) }
    }

    /// Выбор раздела. Повторный выбор уже открытого раздела в боковом меню SwiftUI сообщает тем же значением — по нему
    /// раздел возвращается к началу. Полоса вкладок tvOS 17 такого не сообщала (Select там уводит фокус в содержимое),
    /// боковое меню — сообщает (проверено сценарием 19.11.2026).
    private var tabSelection: Binding<MainTab> {
        Binding(get: { tab }, set: { selected in
            if selected == tab {
                switch selected {
                case .home: homePath = []
                case .search: searchPath = []
                case .library: libraryPath = []
                case .settings: break
                }
            }
            tab = selected
        })
    }
}

private extension View {
    /// Шапка меню у SwiftUI — только с tvOS 27; на 18–26 меню без неё. Версия системы на ходу не меняется,
    /// так что ветка постоянна и идентичность экрана не прыгает.
    @ViewBuilder func sidebarHeader(name: String?) -> some View {
        if #available(tvOS 27.0, *) {
            tabViewSidebarHeader { SidebarHeader(name: name) }
        } else {
            self
        }
    }
}

/// Шапка бокового меню: кто вошёл (как имя профиля у приложения Apple TV).
private struct SidebarHeader: View {
    let name: String?

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.title2)
                .foregroundStyle(.secondary)
            if let name, !name.isEmpty {
                Text(name).font(.headline).lineLimit(1)
            }
        }
    }
}

enum MainTab: String, Hashable {
    case home, search, library, settings

    /// Сразу открыть вкладку — для проверок без пульта: `-tab search`.
    static var fromLaunchArguments: MainTab? { LaunchArgument.value("-tab").flatMap(MainTab.init(rawValue:)) }
}

enum LaunchArgument {
    /// Значение после ключа в аргументах запуска (`-tab search` → `search`).
    static func value(_ key: String) -> String? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: key), i + 1 < args.count else { return nil }
        return args[i + 1]
    }
}

extension Route {
    /// Сразу открыть экран — для проверок без пульта: `-route media:846`, `library:43`, `playlist:7`.
    static var fromLaunchArguments: Route? {
        guard let value = LaunchArgument.value("-route") else { return nil }
        let parts = value.split(separator: ":", maxSplits: 1).map(String.init)
        guard parts.count == 2 else { return nil }
        switch parts[0] {
        case "media": return .media(parts[1])
        case "library": return .library(LibraryRef(id: parts[1], title: "", itemCount: 0))
        case "playlist": return .playlist(parts[1])
        default: return nil
        }
    }
}

extension PlayRequest {
    /// Сразу открыть плеер — для проверок без пульта: `-play media:846`, `-play media:846:beginning`, `-play channel:3`.
    static var fromLaunchArguments: PlayRequest? {
        guard let value = LaunchArgument.value("-play") else { return nil }
        let parts = value.split(separator: ":").map(String.init)
        guard parts.count >= 2 else { return nil }
        switch parts[0] {
        case "media": return .media(parts[1], start: parts.count > 2 && parts[2] == "beginning" ? .beginning : .resume)
        case "channel": return .channel(parts[1])
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
    /// Перечитывать при своём изменении состояния зрителя (`AppModel.viewerRevision`, MF-116): ленты, полосы и сердечки
    /// после карточки и плеера. Не «при появлении»: с боковым меню при возврате из стека раздела оно не приходит.
    var reloadOnViewerChange = false

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
        // Первая загрузка и перечитывание по смене номера — одна задача; при сбое перечитывания остаётся прежнее.
        .task(id: reloadOnViewerChange ? app.viewerRevision : 0) { await run() }
    }

    private func run() async {
        guard let catalog = app.catalog else { return }
        do {
            value = try await load(catalog)
            error = nil
        } catch is CancellationError {
        } catch {
            let e = AppError.from(error)
            if e.isAppWide || e.is(.serverUnavailable) || e.is(.network) && value == nil {
                await app.handle(e)
            } else {
                self.error = e
            }
        }
    }
}
