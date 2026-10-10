import AppKit
import Carbon.HIToolbox

/// A single keyboard shortcut: one key code plus a set of modifier flags.
/// Stored as raw Cocoa values (NSEvent.ModifierFlags.rawValue) since that's
/// what we capture from key events; converted to Carbon's modifier
/// constants only at the point of registering the global hotkey.
struct KeyCombo: Codable, Equatable {
    var keyCode: UInt32
    var modifierFlags: UInt32

    static let `default` = KeyCombo(
        keyCode: UInt32(kVK_ANSI_V),
        modifierFlags: UInt32(NSEvent.ModifierFlags([.command, .shift]).rawValue)
    )

    var cocoaModifiers: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: UInt(modifierFlags))
    }

    var carbonModifiers: UInt32 {
        var carbon: UInt32 = 0
        let mods = cocoaModifiers
        if mods.contains(.command) { carbon |= UInt32(cmdKey) }
        if mods.contains(.option) { carbon |= UInt32(optionKey) }
        if mods.contains(.control) { carbon |= UInt32(controlKey) }
        if mods.contains(.shift) { carbon |= UInt32(shiftKey) }
        return carbon
    }

    /// Human-readable form, e.g. "⌘⇧V".
    var displayString: String {
        let mods = cocoaModifiers
        var symbols = ""
        if mods.contains(.control) { symbols += "⌃" }
        if mods.contains(.option) { symbols += "⌥" }
        if mods.contains(.shift) { symbols += "⇧" }
        if mods.contains(.command) { symbols += "⌘" }
        return symbols + Self.keyLabel(for: keyCode)
    }

    /// Covers letters, digits, and a handful of common non-letter keys.
    /// Falls back to "Key <code>" for anything not in the table rather
    /// than silently showing nothing.
    static func keyLabel(for keyCode: UInt32) -> String {
        let table: [UInt32: String] = [
            UInt32(kVK_ANSI_A): "A", UInt32(kVK_ANSI_B): "B", UInt32(kVK_ANSI_C): "C",
            UInt32(kVK_ANSI_D): "D", UInt32(kVK_ANSI_E): "E", UInt32(kVK_ANSI_F): "F",
            UInt32(kVK_ANSI_G): "G", UInt32(kVK_ANSI_H): "H", UInt32(kVK_ANSI_I): "I",
            UInt32(kVK_ANSI_J): "J", UInt32(kVK_ANSI_K): "K", UInt32(kVK_ANSI_L): "L",
            UInt32(kVK_ANSI_M): "M", UInt32(kVK_ANSI_N): "N", UInt32(kVK_ANSI_O): "O",
            UInt32(kVK_ANSI_P): "P", UInt32(kVK_ANSI_Q): "Q", UInt32(kVK_ANSI_R): "R",
            UInt32(kVK_ANSI_S): "S", UInt32(kVK_ANSI_T): "T", UInt32(kVK_ANSI_U): "U",
            UInt32(kVK_ANSI_V): "V", UInt32(kVK_ANSI_W): "W", UInt32(kVK_ANSI_X): "X",
            UInt32(kVK_ANSI_Y): "Y", UInt32(kVK_ANSI_Z): "Z",
            UInt32(kVK_ANSI_0): "0", UInt32(kVK_ANSI_1): "1", UInt32(kVK_ANSI_2): "2",
            UInt32(kVK_ANSI_3): "3", UInt32(kVK_ANSI_4): "4", UInt32(kVK_ANSI_5): "5",
            UInt32(kVK_ANSI_6): "6", UInt32(kVK_ANSI_7): "7", UInt32(kVK_ANSI_8): "8",
            UInt32(kVK_ANSI_9): "9",
            UInt32(kVK_Space): "Space", UInt32(kVK_Tab): "Tab", UInt32(kVK_Return): "Return",
            UInt32(kVK_Delete): "Delete", UInt32(kVK_Escape): "Esc",
        ]
        return table[keyCode] ?? "Key \(keyCode)"
    }
}
