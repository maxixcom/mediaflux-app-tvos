import SwiftUI

/// Поиск по своим материалам: штатная строка поиска tvOS, запрос — от 2 символов, после паузы в наборе.
struct SearchView: View {
    @Environment(AppModel.self) private var app
    @State private var text = ""
    @State private var results: [MediaItem] = []
    @State private var total = 0
    @State private var searching = false
    @State private var error: AppError?

    private let columns = [GridItem(.adaptive(minimum: CardSize.width, maximum: CardSize.width), spacing: 48)]

    var body: some View {
        ScrollView(.vertical) {
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
        .searchable(text: $text, prompt: Text("Название или описание"))
        .task(id: text) { await search() }
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
            if e.needsSignIn { await app.handle(e) } else { self.error = e }
        }
    }
}

extension Catalog {
    func search(_ text: String) async throws -> (items: [MediaItem], totalCount: Int) {
        let s = try await api.fetch(DCAPI.SearchQuery(text: text)).search
        return (s.nodes.map { MediaItem($0.fragments.mediaCard) }, s.totalCount)
    }
}
