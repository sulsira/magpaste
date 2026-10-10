import SwiftUI

/// What the popover in ContentView's "+" pill / section context menu is
/// editing — a brand new section, or an existing one (rename + recolor).
enum SectionEditorTarget: Identifiable {
    case new
    case edit(Section)

    var id: String {
        switch self {
        case .new: return "new"
        case .edit(let section): return section.id.uuidString
        }
    }

    var isNew: Bool {
        if case .new = self { return true }
        return false
    }
}

struct SectionEditorView: View {
    let target: SectionEditorTarget
    let onSave: (String, Color) -> Void
    let onDelete: (() -> Void)?
    let onCancel: () -> Void

    @State private var name: String
    @State private var color: Color

    init(
        target: SectionEditorTarget,
        onSave: @escaping (String, Color) -> Void,
        onDelete: (() -> Void)?,
        onCancel: @escaping () -> Void
    ) {
        self.target = target
        self.onSave = onSave
        self.onDelete = onDelete
        self.onCancel = onCancel
        switch target {
        case .new:
            _name = State(initialValue: "")
            _color = State(initialValue: MagpasteTheme.sectionPalette.randomElement() ?? MagpasteTheme.wingBlue)
        case .edit(let section):
            _name = State(initialValue: section.name)
            _color = State(initialValue: Color(hex: section.colorHex))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(target.isNew ? "New Section" : "Edit Section")
                .font(.system(size: 13, weight: .semibold))

            TextField("Section name", text: $name)
                .textFieldStyle(.roundedBorder)
                .onSubmit(save)

            ColorPicker("Color", selection: $color, supportsOpacity: false)

            HStack {
                if !target.isNew, let onDelete {
                    Button("Delete", role: .destructive, action: onDelete)
                }
                Spacer()
                Button("Cancel", action: onCancel)
                Button(target.isNew ? "Add" : "Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .frame(width: 220)
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        onSave(name, color)
    }
}
