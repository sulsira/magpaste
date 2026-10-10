import SwiftUI
import AppKit

private enum Filter: Equatable {
    case all
    case section(UUID)
}

struct ContentView: View {
    @ObservedObject private var monitor = ClipboardMonitor.shared
    @ObservedObject private var sectionManager = SectionManager.shared
    @ObservedObject private var edgeManager = PanelEdgeManager.shared
    @State private var searchText: String = ""
    @State private var selectedFilter: Filter = .all
    @State private var selectedIDs: Set<UUID> = []
    @State private var focusedIndex: Int = 0
    @State private var anchorIndex: Int = 0
    @State private var sectionEditorTarget: SectionEditorTarget?
    @FocusState private var searchFieldFocused: Bool

    private let cardWidth: CGFloat = 220

    private var filteredItems: [ClipboardItem] {
        let byFilter: [ClipboardItem]
        switch selectedFilter {
        case .all:
            byFilter = monitor.items
        case .section(let id):
            byFilter = monitor.items.filter { $0.sectionID == id }
        }
        let bySearch = searchText.isEmpty
            ? byFilter
            : byFilter.filter { $0.content.localizedCaseInsensitiveContains(searchText) }
        return bySearch.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
            return lhs.dateCopied > rhs.dateCopied
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            searchBar
            tabPills

            if filteredItems.isEmpty {
                emptyState
            } else {
                cardsScrollView
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MagpasteTheme.panelBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MagpasteTheme.cardBorder, lineWidth: 1)
        )
        .onAppear { searchFieldFocused = true; resetSelectionToFirst() }
        .onChange(of: searchText) { _, _ in resetSelectionToFirst() }
        .onChange(of: selectedFilter) { _, _ in resetSelectionToFirst() }
        .onKeyPress { press in
            switch press.key {
            case .leftArrow, .upArrow:
                handleArrow(delta: -1, extend: press.modifiers.contains(.shift))
                return .handled
            case .rightArrow, .downArrow:
                handleArrow(delta: 1, extend: press.modifiers.contains(.shift))
                return .handled
            case .delete, .deleteForward:
                // Only treat Delete as "remove the selected card(s)" when the
                // search field is empty — otherwise it's just editing the query.
                guard searchText.isEmpty else { return .ignored }
                deleteSelected()
                return .handled
            default:
                return .ignored
            }
        }
    }

    /// A single row of cards you scroll through sideways (horizontal layout),
    /// or a single column you scroll through up/down (vertical layout).
    private var cardsScrollView: some View {
        ScrollViewReader { proxy in
            Group {
                if !edgeManager.edge.isVertical {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 12) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                cardView(index: index, item: item)
                                    .frame(width: cardWidth)
                            }
                        }
                    }
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                                cardView(index: index, item: item)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
            .onChange(of: focusedIndex) { _, newValue in
                guard filteredItems.indices.contains(newValue) else { return }
                withAnimation {
                    proxy.scrollTo(filteredItems[newValue].id, anchor: .center)
                }
            }
        }
    }

    private func cardView(index: Int, item: ClipboardItem) -> some View {
        ClipboardItemCard(
            item: item,
            index: index,
            isSelected: selectedIDs.contains(item.id),
            onSelect: { handleSelect(index: index, item: item) },
            onTogglePin: { togglePin(item) }
        )
        .id(item.id)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(MagpasteTheme.textMuted)
                .font(.system(size: 13))

            TextField("Search clipboard history…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(MagpasteTheme.textPrimary)
                .focused($searchFieldFocused)
                .onSubmit(pasteSelected)

            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(MagpasteTheme.textMuted)
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(MagpasteTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(MagpasteTheme.cardBorder, lineWidth: 1)
        )
        .padding(.bottom, 10)
    }

    private var tabPills: some View {
        HStack(spacing: 8) {
            allPill
            ForEach(sectionManager.sections) { section in
                sectionPill(section)
            }
            addSectionPill
        }
        .padding(.bottom, 12)
        .popover(item: $sectionEditorTarget) { target in
            SectionEditorView(
                target: target,
                onSave: { name, color in
                    switch target {
                    case .new:
                        sectionManager.addSection(name: name, color: color)
                    case .edit(let section):
                        sectionManager.rename(section.id, to: name)
                        sectionManager.recolor(section.id, to: color)
                    }
                    sectionEditorTarget = nil
                },
                onDelete: {
                    if case .edit(let section) = target {
                        deleteSection(section)
                    }
                    sectionEditorTarget = nil
                },
                onCancel: { sectionEditorTarget = nil }
            )
        }
    }

    private var allPill: some View {
        pill(label: "All", color: nil, isSelected: selectedFilter == .all) {
            selectedFilter = .all
        }
        .dropDestination(for: String.self) { droppedIDs, _ in
            assignDroppedItem(droppedIDs, to: nil)
        }
    }

    private func sectionPill(_ section: Section) -> some View {
        let isSelected = selectedFilter == .section(section.id)
        return pill(label: section.name, color: Color(hex: section.colorHex), isSelected: isSelected) {
            selectedFilter = .section(section.id)
        }
        .contextMenu {
            Button("Edit…") { sectionEditorTarget = .edit(section) }
            Button("Delete", role: .destructive) { deleteSection(section) }
        }
        .dropDestination(for: String.self) { droppedIDs, _ in
            assignDroppedItem(droppedIDs, to: section.id)
        }
    }

    private var addSectionPill: some View {
        Button(action: { sectionEditorTarget = .new }) {
            Image(systemName: "plus")
                .font(.system(size: 11, weight: .medium))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .foregroundStyle(MagpasteTheme.textSecondary)
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(MagpasteTheme.cardBorder, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private func pill(label: String, color: Color?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if let color {
                    Circle().fill(color).frame(width: 6, height: 6)
                }
                Text(label)
                    .font(.system(size: 12, weight: isSelected ? .medium : .regular))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? MagpasteTheme.cardBackground : .clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(isSelected ? MagpasteTheme.cardBorder : .clear, lineWidth: 1)
            )
            .foregroundStyle(isSelected ? MagpasteTheme.textPrimary : MagpasteTheme.textSecondary)
        }
        .buttonStyle(.plain)
    }

    private func assignDroppedItem(_ droppedIDs: [String], to sectionID: UUID?) -> Bool {
        guard let idString = droppedIDs.first, let itemID = UUID(uuidString: idString) else { return false }
        monitor.assignSection(itemID, to: sectionID)
        return true
    }

    private func deleteSection(_ section: Section) {
        sectionManager.delete(section.id)
        if selectedFilter == .section(section.id) { selectedFilter = .all }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "doc.on.clipboard")
                .font(.system(size: 26))
                .foregroundStyle(MagpasteTheme.textMuted)
            Text(searchText.isEmpty ? "No clips yet" : "No matches")
                .font(.system(size: 13))
                .foregroundStyle(MagpasteTheme.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func togglePin(_ item: ClipboardItem) {
        monitor.togglePin(item.id)
    }

    private func paste(_ item: ClipboardItem) {
        HistoryPanel.shared.hidePanel()
        PasteExecutor.paste(item)
    }

    /// Merges multiple selected clips into one paste, in their on-screen
    /// (sorted/filtered) order, each on its own line.
    private func pasteMerged(_ items: [ClipboardItem]) {
        HistoryPanel.shared.hidePanel()
        PasteExecutor.pasteRaw(items.map(\.content).joined(separator: "\n"))
    }

    /// Pressing Return (from the search field, which holds focus by
    /// default) has the same effect as clicking the currently selected
    /// card(s) — a single selection pastes that clip, a multi-selection
    /// pastes all of them merged together.
    private func pasteSelected() {
        let selected = filteredItems.filter { selectedIDs.contains($0.id) }
        guard !selected.isEmpty else { return }
        if selected.count == 1 {
            paste(selected[0])
        } else {
            pasteMerged(selected)
        }
    }

    /// Plain click selects & pastes immediately (unchanged single-item
    /// behavior). Shift-click extends the range from the last anchor,
    /// Cmd-click toggles just that card — neither pastes right away, so
    /// Enter is needed to commit a multi-selection.
    private func handleSelect(index: Int, item: ClipboardItem) {
        let flags = NSEvent.modifierFlags
        if flags.contains(.shift) {
            extendSelection(to: index)
        } else if flags.contains(.command) {
            toggleSelection(at: index)
        } else {
            selectOnly(index: index)
            paste(item)
        }
    }

    private func selectOnly(index: Int) {
        guard filteredItems.indices.contains(index) else { return }
        focusedIndex = index
        anchorIndex = index
        selectedIDs = [filteredItems[index].id]
    }

    private func toggleSelection(at index: Int) {
        guard filteredItems.indices.contains(index) else { return }
        let id = filteredItems[index].id
        if selectedIDs.contains(id) {
            selectedIDs.remove(id)
        } else {
            selectedIDs.insert(id)
        }
        focusedIndex = index
        anchorIndex = index
    }

    private func extendSelection(to index: Int) {
        guard filteredItems.indices.contains(index) else { return }
        focusedIndex = index
        let lower = min(anchorIndex, index)
        let upper = max(anchorIndex, index)
        selectedIDs = Set(filteredItems[lower...upper].map(\.id))
    }

    private func handleArrow(delta: Int, extend: Bool) {
        guard !filteredItems.isEmpty else { return }
        let newIndex = min(max(focusedIndex + delta, 0), filteredItems.count - 1)
        if extend {
            extendSelection(to: newIndex)
        } else {
            selectOnly(index: newIndex)
        }
    }

    /// Deletes every currently selected card, then moves the selection to
    /// whatever now sits at the same spot (or the previous item, if the
    /// deletion emptied the tail of the list).
    private func deleteSelected() {
        guard !selectedIDs.isEmpty else { return }
        let deleteIndex = filteredItems.firstIndex { selectedIDs.contains($0.id) } ?? focusedIndex
        selectedIDs.forEach { monitor.delete($0) }

        let newIndex = min(deleteIndex, filteredItems.count - 1)
        if filteredItems.indices.contains(newIndex) {
            selectOnly(index: newIndex)
        } else {
            selectedIDs = []
            focusedIndex = 0
            anchorIndex = 0
        }
    }

    private func resetSelectionToFirst() {
        focusedIndex = 0
        anchorIndex = 0
        selectedIDs = filteredItems.first.map { [$0.id] } ?? []
    }
}

#Preview {
    ContentView()
}
