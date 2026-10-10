import Foundation

enum KeyComboStore {
    private static let keyCodeKey = "shortcut.keyCode"
    private static let modifiersKey = "shortcut.modifierFlags"

    static func load() -> KeyCombo {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: keyCodeKey) != nil else { return .default }
        let keyCode = UInt32(defaults.integer(forKey: keyCodeKey))
        let modifiers = UInt32(defaults.integer(forKey: modifiersKey))
        return KeyCombo(keyCode: keyCode, modifierFlags: modifiers)
    }

    static func save(_ combo: KeyCombo) {
        let defaults = UserDefaults.standard
        defaults.set(Int(combo.keyCode), forKey: keyCodeKey)
        defaults.set(Int(combo.modifierFlags), forKey: modifiersKey)
    }
}
