import SwiftUI

/// Owns the user-created sections (name + color) that clips can be dragged
/// into. Unlike the built-in "All" filter, sections only exist once the user
/// adds one — clips start unassigned (sectionID == nil) and only ever leave
/// "All" when dragged onto a section pill.
final class SectionManager: ObservableObject {

    static let shared = SectionManager()

    @Published private(set) var sections: [Section] = [] {
        didSet { persist() }
    }

    private let persistenceQueue = DispatchQueue(label: "com.sulsira.Magpaste.sections.persistence", qos: .utility)

    private init() {
        sections = SectionStore.load()
    }

    private func persist() {
        let snapshot = sections
        persistenceQueue.async {
            SectionStore.save(snapshot)
        }
    }

    func addSection(name: String, color: Color) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        sections.append(Section(name: trimmed, colorHex: color.toHexString()))
    }

    func rename(_ id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let idx = sections.firstIndex(where: { $0.id == id }) else { return }
        sections[idx].name = trimmed
    }

    func recolor(_ id: UUID, to color: Color) {
        guard let idx = sections.firstIndex(where: { $0.id == id }) else { return }
        sections[idx].colorHex = color.toHexString()
    }

    func delete(_ id: UUID) {
        sections.removeAll { $0.id == id }
        ClipboardMonitor.shared.unassignSection(id)
    }
}
