import Foundation

/// Стенд и тестовые материалы спайка Э0 (MF-87). Только открытые (PUBLIC) материалы tst: стример проверяет
/// токен витрины так же, как владельческий (APPS.md §8), поэтому адреса берём из публичного конфига.
enum Config {
    static let streamer = URL(string: "https://stream.tst.media-flux.ru")!
    static let issuer = URL(string: "https://id.tst.media-flux.ru/realms/mediaflux")!
    static let clientId = "mediaflux-tv"

    static let items: [TestItem] = [
        TestItem(kind: .media, code: "KcXy8AGnf9", note: "SAMPLE-AES, 20 с, вертикальное"),
        TestItem(kind: .media, code: "CjmpuxJII8", note: "AES-128, Caminandes 3, 2,5 мин"),
        TestItem(kind: .media, code: "tF3ACeXqs5", note: "без шифрования, Sintel, 10 дорожек субтитров"),
        TestItem(kind: .media, code: "9OtqBwqSF9", note: "без шифрования, 3 главы, до 1080p"),
        TestItem(kind: .media, code: "BTP7eiD3Kw", note: "без шифрования, 2 дорожки субтитров, 2,5 ч"),
        TestItem(kind: .media, code: "0kDGYfKWx0", note: "без шифрования, Lucky, 7 глав на разных листах превью"),
        TestItem(kind: .playlist, code: "7V3uCmRxBi", note: "плейлист «Лиля», первый элемент"),
        TestItem(kind: .channel, code: "ksFeHdZjAJ", note: "канал «Тест», без шифрования"),
        TestItem(kind: .channel, code: "32ZkjwRHVL", note: "ШИФРОВАННЫЙ КАНАЛ, SAMPLE-AES")
    ]
}

struct TestItem: Identifiable, Hashable {
    enum Kind: String { case media, playlist, channel }

    let kind: Kind
    let code: String
    let note: String

    var id: String { "\(kind.rawValue):\(code)" }
}

/// Сценарий из аргументов запуска — пультом из терминала не нажмёшь, а замер паузы должен быть повторяемым:
///   -autoplay media:KcXy8AGnf9:mp4   сразу открыть поток (вид:код:упаковка)
///   -seek-to 12                       через 8 с после старта перемотать на 12-ю секунду
///   -pause-after 60                   поставить на паузу через 60 с после старта
///   -resume-after 900                 снять с паузы через 900 с паузы
enum Scenario {
    private static let args = ProcessInfo.processInfo.arguments

    private static func value(_ key: String) -> String? {
        guard let i = args.firstIndex(of: key), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static var autoplay: (TestItem, Packaging)? {
        guard let parts = value("-autoplay")?.split(separator: ":").map(String.init), parts.count == 3,
              let kind = TestItem.Kind(rawValue: parts[0]), let p = Packaging(rawValue: parts[2]) else { return nil }
        let item = Config.items.first { $0.kind == kind && $0.code == parts[1] }
            ?? TestItem(kind: kind, code: parts[1], note: "из аргументов")
        return (item, p)
    }

    static var seekTo: Double? { value("-seek-to").flatMap(Double.init) }
    static var pauseAfter: Double? { value("-pause-after").flatMap(Double.init) }
    static var resumeAfter: Double? { value("-resume-after").flatMap(Double.init) }}

/// Строка журнала с меткой: по ней вывод приложения ищется в консоли `simctl` / `devicectl`.
enum Log {
    private static let fmt: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withTime, .withColonSeparatorInTime, .withFractionalSeconds]
        return f
    }()

    static func line(_ text: String) {
        print("[MF87] \(fmt.string(from: Date())) \(text)")
    }
}
