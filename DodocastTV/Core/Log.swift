import Foundation

/// Строка журнала с меткой `[DCTV]`: по ней вывод приложения ищется в консоли `simctl` / `devicectl`.
/// Токены, коды входа и прочие секреты в журнал не пишем.
enum Log {
    private static let format = Date.ISO8601FormatStyle(includingFractionalSeconds: true).time(includingFractionalSeconds: true)

    static func line(_ text: String) {
        print("[DCTV] \(Date().formatted(format)) \(text)")
    }
}
