import AppKit
import Combine

/// Polls the system pasteboard for changes and maintains the clipboard
/// history as an observable array of ClipboardItem.
///
/// NSPasteboard has no "did change" notification, so polling changeCount
/// on a short timer is the standard approach (this is what Paste, Alfred,
/// Raycast etc. all do under the hood).
final class ClipboardMonitor: ObservableObject {

    static let shared = ClipboardMonitor()

    @Published private(set) var items: [ClipboardItem] = [] {
        didSet { persist() }
    }

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int
    private var timer: Timer?
    private let persistenceQueue = DispatchQueue(label: "com.sulsira.Magpaste.persistence", qos: .utility)

    /// Apps whose clipboard content should never be captured (password
    /// managers etc.). Matched against the frontmost app's bundle identifier
    /// at copy time.
    private let excludedBundleIDs: Set<String> = [
        "com.apple.keychainaccess",
        "com.1password.1password",
        "com.agilebits.onepassword7",
        "com.lastpass.LastPass"
    ]

    private let maxHistoryItems = 500

    private init() {
        lastChangeCount = pasteboard.changeCount
        items = ClipboardHistoryStore.load()
    }

    private func persist() {
        let itemsSnapshot = items
        persistenceQueue.async {
            ClipboardHistoryStore.save(itemsSnapshot)
        }
    }

    func start(pollInterval: TimeInterval = 0.5) {
        stop()
        timer = Timer.scheduledTimer(withTimeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard !isExcludedSource() else { return }
        guard let newItem = readCurrentItem() else { return }

        // Skip exact duplicate of the most recent item (re-copying the same thing).
        if let mostRecent = items.first, mostRecent.content == newItem.content {
            return
        }

        items.insert(newItem, at: 0)
        if items.count > maxHistoryItems {
            items.removeLast(items.count - maxHistoryItems)
        }
    }

    private func readCurrentItem() -> ClipboardItem? {
        let sourceApp = NSWorkspace.shared.frontmostApplication?.localizedName

        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let type: ClipboardItemType = isLikelyURL(string) ? .url : (isHexColor(string) ? .color : .text)
            return ClipboardItem(content: string, type: type, sourceApp: sourceApp)
        }

        // Image/file support intentionally deferred to a later pass —
        // text covers the large majority of clipboard activity.
        return nil
    }

    private func isExcludedSource() -> Bool {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return false }
        return excludedBundleIDs.contains(bundleID)
    }

    private func isLikelyURL(_ string: String) -> Bool {
        guard let url = URL(string: string.trimmingCharacters(in: .whitespacesAndNewlines)),
              let scheme = url.scheme else { return false }
        return ["http", "https"].contains(scheme.lowercased())
    }

    private func isHexColor(_ string: String) -> Bool {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("#") else { return false }
        let hex = trimmed.dropFirst()
        return (hex.count == 6 || hex.count == 3) && hex.allSatisfy { $0.isHexDigit }
    }

    // MARK: - Actions

    func togglePin(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isPinned.toggle()
    }

    func delete(_ id: UUID) {
        items.removeAll { $0.id == id }
    }

    func clearAll(keepPinned: Bool = true) {
        items = keepPinned ? items.filter(\.isPinned) : []
    }

    /// Drags a card onto a section pill (or back onto "All", via `nil`).
    func assignSection(_ itemID: UUID, to sectionID: UUID?) {
        guard let idx = items.firstIndex(where: { $0.id == itemID }) else { return }
        items[idx].sectionID = sectionID
    }

    /// Called when a section is deleted — its clips fall back to unassigned
    /// rather than disappearing.
    func unassignSection(_ sectionID: UUID) {
        items = items.map { item in
            guard item.sectionID == sectionID else { return item }
            var updated = item
            updated.sectionID = nil
            return updated
        }
    }
}
