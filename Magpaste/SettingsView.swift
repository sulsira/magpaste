import SwiftUI

struct SettingsView: View {
    @State private var combo: KeyCombo = KeyComboStore.load()
    @State private var isRecording = false
    @ObservedObject private var edgeManager = PanelEdgeManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Toggle Clipboard History")
                .font(.system(size: 13, weight: .semibold))

            HStack(spacing: 10) {
                ZStack {
                    Text(isRecording ? "Press new shortcut…" : combo.displayString)
                        .font(.system(size: 13, design: .monospaced))
                        .frame(width: 170, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isRecording ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.06))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isRecording ? Color.accentColor : .clear, lineWidth: 1.5)
                        )
                        .onTapGesture { isRecording = true }

                    ShortcutRecorder(isRecording: $isRecording) { newCombo in
                        combo = newCombo
                        KeyComboStore.save(newCombo)
                        HotKeyManager.shared.register(newCombo)
                    }
                    .frame(width: 170, height: 28)
                }

                Button("Reset") {
                    combo = .default
                    KeyComboStore.save(.default)
                    HotKeyManager.shared.register(.default)
                }
                .buttonStyle(.link)
            }

            Text("Click the field, then press your new key combination. Must include ⌘, ⌥, or ⌃ so it can't collide with normal typing.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Divider()

            Text("Panel Position")
                .font(.system(size: 13, weight: .semibold))

            Picker("", selection: $edgeManager.edge) {
                Text("Left").tag(PanelEdge.left)
                Text("Right").tag(PanelEdge.right)
                Text("Top").tag(PanelEdge.top)
                Text("Bottom").tag(PanelEdge.bottom)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 300)

            Text("Left/Right dock a tall sidebar of cards to that edge; Top/Bottom dock a wide bar of cards to that edge.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(24)
        .frame(width: 380, height: 300)
    }
}

#Preview {
    SettingsView()
}
