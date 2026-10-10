import AppKit

/// Handles the "select a history item -> it appears in the frontmost app"
/// flow: write the content back to NSPasteboard, reactivate whatever app
/// was focused before the panel stole focus, then synthesize a ⌘V.
enum PasteExecutor {

    /// Set by HistoryPanel right before it activates itself, so we know
    /// which app to hand focus back to.
    static var previousApp: NSRunningApplication?

    static func paste(_ item: ClipboardItem) {
        pasteRaw(item.content)
    }

    /// Pastes arbitrary text directly — used when several selected cards
    /// are merged into a single paste rather than pasting one clip's content.
    static func pasteRaw(_ content: String) {
        writeToPasteboard(content)

        guard let app = previousApp else { return }

        app.activate(options: [.activateIgnoringOtherApps])

        // Give macOS a beat to actually switch focus before we synthesize
        // the keystroke, otherwise ⌘V can land on the wrong (still-frontmost) app.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            simulateCommandV()
        }
    }

    private static func writeToPasteboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
    }

    private static func simulateCommandV() {
        // Requires Accessibility permission (System Settings > Privacy &
        // Security > Accessibility) the first time this runs.
        guard let source = CGEventSource(stateID: .hidSystemState) else { return }

        let vKeyCode: CGKeyCode = 9 // 'v'

        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) else { return }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
