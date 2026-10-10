import SwiftUI

struct ClipboardItemCard: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    var onSelect: () -> Void = {}
    var onTogglePin: () -> Void = {}

    @ObservedObject private var sectionManager = SectionManager.shared
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Text(item.preview)
                .font(.system(size: 11))
                .foregroundStyle(MagpasteTheme.textSecondary)
                .lineLimit(9)
                .frame(maxWidth: .infinity, minHeight: 130, alignment: .topLeading)
                .padding(10)

            Divider().overlay(MagpasteTheme.divider)

            HStack {
                if index < 9 {
                    Text("⌘\(index + 1)")
                }
                Spacer()
                Text("\(item.content.count) ch")
            }
            .font(.system(size: 10))
            .foregroundStyle(MagpasteTheme.textMuted)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
        }
        .background(MagpasteTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(isSelected ? MagpasteTheme.wingBlue : MagpasteTheme.cardBorder, lineWidth: isSelected ? 1.5 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
        .onHover { hovering in isHovering = hovering }
        .draggable(item.id.uuidString)
        .overlay(alignment: .topTrailing) {
            if item.isPinned || isHovering {
                Button(action: onTogglePin) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .font(.system(size: 9))
                        .foregroundStyle(item.isPinned ? MagpasteTheme.tailGreen : MagpasteTheme.textMuted)
                        .padding(6)
                        .background(
                            Circle().fill(MagpasteTheme.cardBackground.opacity(0.9))
                        )
                }
                .buttonStyle(.plain)
                .padding(4)
            }
        }
    }

    private var header: some View {
        ZStack(alignment: .topLeading) {
            headerTint

            VStack(alignment: .leading, spacing: 2) {
                Text(typeLabel)
                    .font(.system(size: 13, weight: .semibold))
                Text(item.timeLabel)
                    .font(.system(size: 9))
                    .opacity(0.75)
            }
            .foregroundStyle(headerInk)
            .padding(10)

            HStack {
                Spacer()
                Image(systemName: typeSymbol)
                    .font(.system(size: 13))
                    .foregroundStyle(headerInk)
            }
            .padding(10)
        }
        .frame(height: 46)
    }

    private var typeLabel: String {
        switch item.type {
        case .text: return "Text"
        case .url: return "Link"
        case .color: return "Color"
        case .image: return "Image"
        }
    }

    private var typeSymbol: String {
        switch item.type {
        case .text: return "doc.text"
        case .url: return "link"
        case .color: return "paintpalette"
        case .image: return "photo"
        }
    }

    /// The section this card has been dragged into, if any — its color
    /// takes over the header so a card's tag is visible at a glance even
    /// while browsing "All".
    private var assignedSection: Section? {
        guard let sectionID = item.sectionID else { return nil }
        return sectionManager.sections.first { $0.id == sectionID }
    }

    private var headerTint: Color {
        if let section = assignedSection {
            return Color(hex: section.colorHex).opacity(0.22)
        }
        switch item.type {
        case .text: return MagpasteTheme.neutralTint
        case .url: return MagpasteTheme.wingBlueTint
        case .color: return colorFromHex(item.content) ?? MagpasteTheme.tailGreenTint
        case .image: return MagpasteTheme.tailGreenTint
        }
    }

    private var headerInk: Color {
        if let section = assignedSection {
            return Color(hex: section.colorHex).darkened()
        }
        switch item.type {
        case .text: return MagpasteTheme.neutralInk
        case .url: return MagpasteTheme.wingBlueInk
        case .color: return .white
        case .image: return MagpasteTheme.tailGreenInk
        }
    }

    private func colorFromHex(_ hex: String) -> Color? {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "#", with: "")
        guard cleaned.count == 6, UInt32(cleaned, radix: 16) != nil else { return nil }
        return Color(hex: cleaned)
    }
}
