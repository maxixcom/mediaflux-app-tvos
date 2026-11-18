import Foundation
import Security

/// Строки в Keychain: refresh-токены серверов и идентификатор установки (APPS.md §6). Сервис — bundle id приложения.
enum Keychain {
    private static var service: String { Bundle.main.bundleIdentifier ?? "app" }

    static func read(_ account: String) -> String? {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: service,
                                kSecAttrAccount as String: account,
                                kSecReturnData as String: true,
                                kSecMatchLimit as String: kSecMatchLimitOne]
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let d = out as? Data else { return nil }
        return String(data: d, encoding: .utf8)
    }

    static func write(_ account: String, _ value: String) {
        let base: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrService as String: service,
                                   kSecAttrAccount as String: account]
        let data = Data(value.utf8)
        if SecItemUpdate(base as CFDictionary, [kSecValueData as String: data] as CFDictionary) == errSecItemNotFound {
            var add = base
            add[kSecValueData as String] = data
            add[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            SecItemAdd(add as CFDictionary, nil)
        }
    }

    static func delete(_ account: String) {
        let q: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                kSecAttrService as String: service,
                                kSecAttrAccount as String: account]
        SecItemDelete(q as CFDictionary)
    }

    /// Постоянный идентификатор установки: заводится один раз, при выходе и смене сервера НЕ стирается — с ним
    /// повторный вход на тот же сервер не тратит слот устройства.
    static var installationId: String {
        if let id = read("installation-id") { return id }
        let id = UUID().uuidString.lowercased()
        write("installation-id", id)
        return id
    }
}
