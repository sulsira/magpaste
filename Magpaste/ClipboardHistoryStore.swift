import Foundation

/// Persists clipboard history to disk as JSON so it survives relaunches.
enum ClipboardHistoryStore {
    private static let directory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("Magpaste", isDirectory: true)
    }()

    private static let fileURL = directory.appendingPathComponent("history.json")

    static func load() -> [ClipboardItem] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([ClipboardItem].self, from: data)) ?? []
    }

    static func save(_ items: [ClipboardItem]) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(items)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Magpaste: failed to save clipboard history: \(error)")
        }
    }
}
