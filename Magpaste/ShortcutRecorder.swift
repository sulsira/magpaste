import SwiftUI
import AppKit

/// The underlying AppKit view: when `isRecording` is true and it has focus,
/// the next key press (with at least one modifier) becomes the new combo.
final class RecorderNSView: NSView {
    var onCapture: ((KeyCombo) -> Void)?
    private var isRecording = false

    override var acceptsFirstResponder: Bool { true }

    func beginRecording() {
        isRecording = true
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        let relevantModifiers: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
        let pressed = event.modifierFlags.intersection(relevantModifiers)

        guard !pressed.isEmpty else {
            // Require at least one modifier so a plain letter key typed
            // elsewhere in the app can never be mistaken for a shortcut.
            NSSound.beep()
            return
        }

        let combo = KeyCombo(keyCode: UInt32(event.keyCode), modifierFlags: UInt32(pressed.rawValue))
        isRecording = false
        onCapture?(combo)
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        return super.resignFirstResponder()
    }
}

/// SwiftUI wrapper. Overlay this on the recorder button so it can become
/// first responder and intercept the next key press.
struct ShortcutRecorder: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onCapture: (KeyCombo) -> Void

    func makeNSView(context: Context) -> RecorderNSView {
        let view = RecorderNSView()
        view.onCapture = { combo in
            isRecording = false
            onCapture(combo)
        }
        return view
    }

    func updateNSView(_ nsView: RecorderNSView, context: Context) {
        if isRecording {
            nsView.beginRecording()
        }
    }
}
