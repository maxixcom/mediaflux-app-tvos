import SwiftUI

/// Главный экран — ленты (APPS.md §4): «Продолжить просмотр», «Недавно добавленные», «Избранное», по ленте на
/// библиотеку, «Каналы». Пустые ленты не показываем. Возврат с карточки перечитывает ленты: избранное и
/// «просмотрено» меняются там.
struct HomeView: View {
    var body: some View {
        Loadable(load: { try await $0.home() }, content: { data in
            if data.isEmpty {
                VStack(spacing: 24) {
                    Image(Brand.logo).resizable().scaledToFit().frame(height: 64)
                    Text("Здесь появятся ваши материалы — загрузите их в личном кабинете.")
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 1000)
                }
            } else {
                rows(data)
            }
        }, reloadOnAppear: true)
    }

    private func rows(_ data: HomeData) -> some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 48) {
                if !data.continueWatching.isEmpty {
                    Row(title: String(localized: "Продолжить просмотр"), items: data.continueWatching) { MediaCard(item: $0) }
                }
                if !data.recent.isEmpty {
                    Row(title: String(localized: "Недавно добавленные"), items: data.recent) { MediaCard(item: $0) }
                }
                if !data.favorites.isEmpty {
                    Row(title: String(localized: "Избранное"), items: data.favorites) { FavoriteCard(item: $0) }
                }
                ForEach(data.shelves) { shelf in
                    Row(title: shelf.library.title, items: shelf.items) { MediaCard(item: $0) }
                }
                if !data.channels.isEmpty {
                    Row(title: String(localized: "Каналы"), items: data.channels) { ChannelCard(item: $0) }
                }
            }
            .padding(.vertical, 40)
        }
    }
}

struct FavoriteCard: View {
    let item: FavoriteItem

    var body: some View {
        switch item {
        case let .media(m): MediaCard(item: m)
        case let .playlist(p): PlaylistCard(item: p)
        case let .channel(c): ChannelCard(item: c)
        }
    }
}
