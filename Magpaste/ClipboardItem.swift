import Foundation

enum ClipboardItemType: String, Codable {
    case text
    case url
    case color
    case image
}

struct ClipboardItem: Identifiable, Equatable, Codable {
    let id: UUID
    var content: String
    var type: ClipboardItemType
    var dateCopied: Date
    var isPinned: Bool
    var sourceApp: String?
    var sectionID: UUID?

    init(
        id: UUID = UUID(),
        content: String,
        type: ClipboardItemType = .text,
        dateCopied: Date = Date(),
        isPinned: Bool = false,
        sourceApp: String? = nil,
        sectionID: UUID? = nil
    ) {
        self.id = id
        self.content = content
        self.type = type
        self.dateCopied = dateCopied
        self.isPinned = isPinned
        self.sourceApp = sourceApp
        self.sectionID = sectionID
    }

    /// Short preview used in the list — collapses whitespace/newlines.
    var preview: String {
        content
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
    }

    /// Relative time label, e.g. "2m ago", "Yesterday".
    var timeLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: dateCopied, relativeTo: Date())
    }
}

extension ClipboardItem {
    /// Sample data so the UI is populated in previews and first-run testing,
    /// before ClipboardMonitor is wired in.
    static let mockData: [ClipboardItem] = [
        ClipboardItem(
            content: "https://example.com/docs/getting-started",
            type: .url,
            dateCopied: Date().addingTimeInterval(-60),
            isPinned: true,
            sourceApp: "Safari"
        ),
        ClipboardItem(
            content: "func clipboardChanged() {\n    checkPasteboard()\n}",
            type: .text,
            dateCopied: Date().addingTimeInterval(-300),
            sourceApp: "Xcode"
        ),
        ClipboardItem(
            content: "#3B82F6",
            type: .color,
            dateCopied: Date().addingTimeInterval(-900),
            sourceApp: "Figma"
        ),
        ClipboardItem(
            content: "Q3 revenue grew 18% year over year, driven mainly by the enterprise tier.",
            type: .text,
            dateCopied: Date().addingTimeInterval(-3600),
            sourceApp: "Notes"
        ),
        ClipboardItem(
            content: "ssh -i ~/.ssh/id_ed25519 user@203.0.113.10",
            type: .text,
            dateCopied: Date().addingTimeInterval(-7200),
            sourceApp: "Terminal"
        ),
        ClipboardItem(
            content: "192.0.2.1",
            type: .text,
            dateCopied: Date().addingTimeInterval(-86400),
            sourceApp: "Terminal"
        ),
    ]
}
