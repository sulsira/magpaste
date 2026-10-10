import SwiftUI
import AppKit

/// A non-activating borderless panel that hosts the clipboard history UI
/// and slides in from the bottom edge of the screen, Spotlight/Raycast-style.
final class HistoryPanel: NSPanel {

    static let shared = HistoryPanel()

    /// Top/bottom: a wide bar spanning the screen, Paste-style.
    private let barHeight: CGFloat = 340
    private let horizontalMargin: CGFloat = 24

    /// Left/right: a tall sidebar spanning most of the screen height.
    private let sidebarWidth: CGFloat = 320
    private let verticalMargin: CGFloat = 24

    /// Gap between the panel and the edge it's docked to, on-screen.
    private let edgeMargin: CGFloat = 24
    /// Extra distance past the edge (beyond the panel's own size) it slides
    /// to when hiding, so it fully clears the edge before disappearing.
    private let hideOvershoot: CGFloat = 40

    private init() {
        super.init(
            contentRect: NSRect(origin: .zero, size: NSSize(width: 480, height: 340)),
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        isMovableByWindowBackground = false
        hidesOnDeactivate = false

        // Dismiss when the user clicks outside the panel.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resignedKey),
            name: NSWindow.didResignKeyNotification,
            object: self
        )

        contentView = NSHostingView(rootView: ContentView())
    }

    @objc private func resignedKey() {
        hidePanel()
    }

    /// Toggles panel visibility, animating in from whichever screen edge is
    /// configured (left/right/top/bottom) on the screen currently under the
    /// mouse cursor.
    func toggle() {
        isVisible ? hidePanel() : showPanel()
    }

    func showPanel() {
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(NSEvent.mouseLocation) })
            ?? NSScreen.main else { return }

        PasteExecutor.previousApp = NSWorkspace.shared.frontmostApplication

        let (onScreenFrame, offScreenFrame) = frames(for: PanelEdgeManager.shared.edge, in: screen.visibleFrame)

        setFrame(offScreenFrame, display: true)
        makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.22
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            animator().setFrame(onScreenFrame, display: true)
        }
    }

    func hidePanel() {
        guard isVisible else { return }
        let (_, offScreenFrame) = frames(for: PanelEdgeManager.shared.edge, in: frame, isCurrentPanelFrame: true)

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.16
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            animator().setFrame(offScreenFrame, display: true)
        }, completionHandler: { [weak self] in
            self?.orderOut(nil)
        })
    }

    /// Computes the on-screen (docked) and off-screen (hidden, past the
    /// edge) frames for a given edge. When called from `hidePanel`, pass the
    /// panel's *current* frame instead of the screen's, since by then the
    /// panel is already sized/positioned on-screen and we just need to slide
    /// it further past the same edge.
    private func frames(for edge: PanelEdge, in referenceFrame: NSRect, isCurrentPanelFrame: Bool = false) -> (onScreen: NSRect, offScreen: NSRect) {
        if isCurrentPanelFrame {
            let current = referenceFrame
            switch edge {
            case .bottom:
                return (current, current.offsetBy(dx: 0, dy: -(barHeight + hideOvershoot)))
            case .top:
                return (current, current.offsetBy(dx: 0, dy: barHeight + hideOvershoot))
            case .left:
                return (current, current.offsetBy(dx: -(sidebarWidth + hideOvershoot), dy: 0))
            case .right:
                return (current, current.offsetBy(dx: sidebarWidth + hideOvershoot, dy: 0))
            }
        }

        let screenFrame = referenceFrame
        switch edge {
        case .bottom:
            let width = screenFrame.width - horizontalMargin * 2
            let x = screenFrame.minX + horizontalMargin
            let onScreen = NSRect(x: x, y: screenFrame.minY + edgeMargin, width: width, height: barHeight)
            let offScreen = NSRect(x: x, y: screenFrame.minY - barHeight, width: width, height: barHeight)
            return (onScreen, offScreen)
        case .top:
            let width = screenFrame.width - horizontalMargin * 2
            let x = screenFrame.minX + horizontalMargin
            let onScreen = NSRect(x: x, y: screenFrame.maxY - barHeight - edgeMargin, width: width, height: barHeight)
            let offScreen = NSRect(x: x, y: screenFrame.maxY, width: width, height: barHeight)
            return (onScreen, offScreen)
        case .left:
            let height = screenFrame.height - verticalMargin * 2
            let y = screenFrame.minY + verticalMargin
            let onScreen = NSRect(x: screenFrame.minX + edgeMargin, y: y, width: sidebarWidth, height: height)
            let offScreen = NSRect(x: screenFrame.minX - sidebarWidth, y: y, width: sidebarWidth, height: height)
            return (onScreen, offScreen)
        case .right:
            let height = screenFrame.height - verticalMargin * 2
            let y = screenFrame.minY + verticalMargin
            let onScreen = NSRect(x: screenFrame.maxX - sidebarWidth - edgeMargin, y: y, width: sidebarWidth, height: height)
            let offScreen = NSRect(x: screenFrame.maxX, y: y, width: sidebarWidth, height: height)
            return (onScreen, offScreen)
        }
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }

    override func keyDown(with event: NSEvent) {
        let escKeyCode: UInt16 = 53
        guard event.keyCode == escKeyCode else {
            super.keyDown(with: event)
            return
        }
        hidePanel()
    }

    /// Escape pressed while the search field (or any other text field) has
    /// focus is delivered here instead of keyDown, via the standard AppKit
    /// key-binding path (NSTextView -> doCommandBySelector -> responder chain).
    override func cancelOperation(_ sender: Any?) {
        hidePanel()
    }
}
