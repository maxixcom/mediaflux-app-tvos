import SwiftUI

/// Поиск по своим материалам: штатная строка поиска tvOS, запрос — от 2 символов, после паузы в наборе.
///
/// Пока строка пуста — ряд «Недавние поиски», как в приложении Apple TV (MF-114): материалы, на чьи карточки переходили
/// из поиска, свежие первыми, общие на аккаунт. Тексты запросов не храним. Выбор — первый шаг стека раздела на
/// карточку медиа: из результатов или из самого ряда недавних (тогда материал поднимается наверх).
struct SearchView: View {
    @Environment(AppModel.self) private var app
    /// Стек раздела «Поиск» (`MainView`): по нему видно, что человек перешёл на карточку.
    @Binding var path: [Route]
    /// Начальный текст — для проверок без пульта: `-search temp`.
    @State private var text = LaunchArgument.value("-search") ?? ""
    @State private var results: [MediaItem] = []
    @State private var total = 0
    @State private var searching = false
    @State private var error: AppError?
    @State private var recents: [MediaItem] = []
    /// Запись последнего выбора: чтение ряда ждёт её, чтобы свой выбор был в нём сразу.
    @State private var pendingRecord: Task<Void, Never>?

    private let columns = [GridItem(.adaptive(minimum: CardSize.width, maximum: CardSize.width), spacing: 48)]

    var body: some View {
        ScrollView(.vertical) {
            if text.isEmpty {
                if !recents.isEmpty {
                    Row(title: String(localized: "Недавние поиски"), items: recents) { MediaCard(item: $0) }
                        .padding(.vertical, 40)
                }
            } else {
                VStack(alignment: .leading, spacing: 32) {
                    if let error {
                        Text(error.message).foregroundStyle(.secondary)
                    } else if text.count >= 2, !searching, results.isEmpty {
                        Text("Ничего не нашлось").foregroundStyle(.secondary)
                    }
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 56) {
                        ForEach(results) { MediaCard(item: $0) }
                    }
                }
                .padding(80)
            }
        }
        .searchable(text: $text, prompt: Text("Название или описание"))
        // Результаты — и по своему изменению состояния зрителя (MF-116): сердечки и полосы после карточки.
        .task(id: SearchKey(text: text, revision: app.viewerRevision)) { await search() }
        // Перечитать, когда ряд становится виден: стёрли текст или вернулись с карточки к пустой строке. На появление
        // экрана не полагаемся: с загрузкой «при появлении» ряд после возврата с карточки оставался прежним (MF-114,
        // найдено владельцем на ТВ, воспроизведено `testRecentsUpdatedAfterReturnAndClearingText`).
        .task(id: recentsVisible) {
            if recentsVisible { await loadRecents() }
        }
        .onChange(of: path) { old, new in
            if old.isEmpty, case let .media(id)? = new.first { record(id) }
        }
    }

    /// Ряд виден: строка поиска пуста и мы на корне раздела.
    private var recentsVisible: Bool { text.isEmpty && path.isEmpty }

    /// Выбор из поиска — в недавние. В фоне: сбой истории не мешает смотреть, кроме «нужен вход».
    private func record(_ mediaId: String) {
        guard let catalog = app.catalog else { return }
        pendingRecord = Task {
            do {
                try await catalog.addSearchRecent(mediaId)
            } catch is CancellationError {
            } catch {
                let e = AppError.from(error)
                if e.isAppWide { await app.handle(e) }
            }
        }
    }

    private func loadRecents() async {
        guard let catalog = app.catalog else { return }
        await pendingRecord?.value
        do {
            recents = try await catalog.searchRecents()
        } catch is CancellationError {
        } catch {
            // Ряд необязательный: при сбое просто не показываем его.
            let e = AppError.from(error)
            if e.isAppWide { await app.handle(e) }
        }
    }

    private func search() async {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard query.count >= 2 else {
            results = []
            error = nil
            return
        }
        // Пауза в наборе: запрос — когда человек перестал печатать (лимит листания на сервере, §10).
        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled, let catalog = app.catalog else { return }
        searching = true
        defer { searching = false }
        do {
            let page = try await catalog.search(query)
            results = page.items
            total = page.totalCount
            error = nil
        } catch is CancellationError {
        } catch {
            let e = AppError.from(error)
            if e.isAppWide { await app.handle(e) } else { self.error = e }
        }
    }
}

/// Ключ перезапуска поиска: текст и номер версии состояния зрителя.
private struct SearchKey: Hashable {
    let text: String
    let revision: Int
}

extension Catalog {
    func search(_ text: String) async throws -> (items: [MediaItem], totalCount: Int) {
        let s = try await api.fetch(DCAPI.SearchQuery(text: text)).search
        return (s.nodes.map { MediaItem($0.fragments.mediaCard) }, s.totalCount)
    }
}
