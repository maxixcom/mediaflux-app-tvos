import SwiftUI

/// Куда ведёт карточка: экраны каталога внутри вкладки (NavigationStack).
enum Route: Hashable {
    case media(String)
    case library(LibraryRef)
    case playlist(String)
    case channel(ChannelItem)
}

enum CardSize {
    static let width: CGFloat = 400
    static var height: CGFloat { width * 9 / 16 }
}

/// Карточка медиа: обложка 16:9 со штатным фокусом tvOS, полоса просмотренного или отметка «просмотрено».
struct MediaCard: View {
    let item: MediaItem

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink(value: Route.media(item.id)) {
                RemoteImage(url: item.coverURL)
                    .frame(width: CardSize.width, height: CardSize.height)
                    .overlay(alignment: .bottom) { progressBar }
                    .overlay(alignment: .topTrailing) { badges }
                    .clipped()
            }
            .buttonStyle(.card)
            // У кнопки — только картинка; подпись — для VoiceOver и сценариев UI-тестов.
            .accessibilityLabel(item.title)
            CardTitle(text: item.title, subtitle: item.durationMs.map(Format.duration))
        }
        .frame(width: CardSize.width)
    }

    @ViewBuilder private var progressBar: some View {
        if let p = item.progress, !p.watched, let fraction = p.fraction(durationMs: item.durationMs), fraction > 0 {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Brand.progressTrack)
                    Capsule().fill(Brand.progressFill).frame(width: max(geo.size.width * fraction, 6))
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 16)
            .padding(.bottom, 14)
        }
    }

    @ViewBuilder private var badges: some View {
        HStack(spacing: 8) {
            if item.favorite { Badge(systemName: "heart.fill") }
            if item.watched { Badge(systemName: "checkmark") }
        }
        .padding(12)
    }
}

struct PlaylistCard: View {
    let item: PlaylistItem

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink(value: Route.playlist(item.id)) {
                RemoteImage(url: item.coverURL, placeholder: "list.bullet.rectangle")
                    .frame(width: CardSize.width, height: CardSize.height)
                    .overlay(alignment: .topTrailing) {
                        if item.favorite { Badge(systemName: "heart.fill").padding(12) }
                    }
                    .clipped()
            }
            .buttonStyle(.card)
            CardTitle(text: item.title, subtitle: Format.itemCount(item.itemCount))
        }
        .frame(width: CardSize.width)
    }
}

/// Карточка канала: своей обложки у канала нет — название на фоне и отметка «в эфире».
struct ChannelCard: View {
    let item: ChannelItem

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink(value: Route.channel(item)) {
                ZStack {
                    LinearGradient(colors: [Color(white: 0.24), Color(white: 0.1)], startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                    Image(systemName: "tv").font(.system(size: 56)).foregroundStyle(.secondary)
                }
                .frame(width: CardSize.width, height: CardSize.height)
                .overlay(alignment: .topLeading) {
                    if item.onAir { OnAirBadge().padding(12) }
                }
                .overlay(alignment: .topTrailing) {
                    if item.favorite { Badge(systemName: "heart.fill").padding(12) }
                }
            }
            .buttonStyle(.card)
            CardTitle(text: item.title, subtitle: nil)
        }
        .frame(width: CardSize.width)
    }
}

struct LibraryCard: View {
    let item: LibraryRef

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            NavigationLink(value: Route.library(item)) {
                RemoteImage(url: item.coverURL, placeholder: "square.stack")
                    .frame(width: CardSize.width, height: CardSize.height)
                    .clipped()
            }
            .buttonStyle(.card)
            CardTitle(text: item.title, subtitle: Format.itemCount(item.itemCount))
        }
        .frame(width: CardSize.width)
    }
}

struct CardTitle: View {
    let text: String
    let subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(text).font(.callout).lineLimit(1)
            if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
        }
    }
}

struct Badge: View {
    let systemName: String

    var body: some View {
        Image(systemName: systemName)
            .font(.caption.weight(.bold))
            .padding(10)
            .background(.black.opacity(0.6), in: Circle())
    }
}

struct OnAirBadge: View {
    var body: some View {
        Text("В эфире")
            .font(.caption2.weight(.bold))
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(.red, in: Capsule())
    }
}

/// Лента: заголовок и карточки в ряд; фокус переходит между лентами по вертикали (`focusSection`).
struct Row<Item: Identifiable, Card: View>: View {
    let title: String
    let items: [Item]
    @ViewBuilder let card: (Item) -> Card

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(title).font(.title3.weight(.semibold)).padding(.horizontal, 80)
            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 48) {
                    ForEach(items) { card($0) }
                }
                .padding(.horizontal, 80)
                .padding(.vertical, 24)
            }
            .scrollClipDisabled()
        }
        .focusSection()
    }
}

/// Длительности и счётчики — по правилам языка устройства.
enum Format {
    static func duration(_ ms: Int) -> String {
        Duration.milliseconds(ms).formatted(.units(allowed: [.hours, .minutes, .seconds], width: .abbreviated,
                                                   maximumUnitCount: 2))
    }

    /// Позиция для «Продолжить с 12:34».
    static func position(_ ms: Int) -> String {
        let d = Duration.milliseconds(ms)
        return ms >= 3_600_000 ? d.formatted(.time(pattern: .hourMinuteSecond)) : d.formatted(.time(pattern: .minuteSecond))
    }

    static func itemCount(_ n: Int) -> String {
        String(localized: "\(n) материалов")
    }
}
