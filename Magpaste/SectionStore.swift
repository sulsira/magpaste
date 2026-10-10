import Foundation

/// Persists user-created sections to disk as JSON so they survive relaunches.
enum SectionStore {
    private static let directory: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("Magpaste", isDirectory: true)
    }()

    private static let fileURL = directory.appendingPathComponent("sections.json")

    static func load() -> [Section] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        return (try? JSONDecoder().decode([Section].self, from: data)) ?? []
    }

    static func save(_ sections: [Section]) {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(sections)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Magpaste: failed to save sections: \(error)")
        }
    }
}
