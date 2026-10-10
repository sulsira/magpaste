import AppKit
import Carbon.HIToolbox

/// Registers a single system-wide keyboard shortcut using Carbon's
/// RegisterEventHotKey. This is still the standard way to do a global
/// hotkey on macOS outside the App Store's more restricted APIs — it
/// works regardless of which app is frontmost and needs no special
/// entitlement.
final class HotKeyManager {

    static let shared = HotKeyManager()

    /// Called on the main thread whenever the registered shortcut fires.
    var action: (() -> Void)?

    private var hotKeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?
    private let hotKeySignature = HotKeyManager.fourCharCode("PClH")

    private init() {
        installEventHandler()
    }

    func register(_ combo: KeyCombo) {
        unregister()

        var hotKeyID = EventHotKeyID(signature: hotKeySignature, id: 1)
        RegisterEventHotKey(
            combo.keyCode,
            combo.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        _ = hotKeyID // silence unused warning in Swift's strict mode
    }

    func unregister() {
        guard let ref = hotKeyRef else { return }
        UnregisterEventHotKey(ref)
        hotKeyRef = nil
    }

    private func installEventHandler() {
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let selfPointer = Unmanaged.passUnretained(self).toOpaque()

        InstallEventHandler(
            GetApplicationEventTarget(),
            { _, _, userData -> OSStatus in
                guard let userData else { return noErr }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue()
                DispatchQueue.main.async {
                    manager.action?()
                }
                return noErr
            },
            1,
            &eventType,
            selfPointer,
            &eventHandlerRef
        )
    }

    private static func fourCharCode(_ string: String) -> FourCharCode {
        var result: FourCharCode = 0
        for scalar in string.unicodeScalars {
            result = (result << 8) + FourCharCode(scalar.value)
        }
        return result
    }
}
