import SwiftUI

// MARK: - Main View

struct ClipboardHistoryView: View {
    @Environment(ClipboardManager.self) private var clipboardManager
    @Environment(PreferencesManager.self) private var preferencesManager

    @Binding var showMetadata: Bool
    @State private var searchText = ""
    @State private var selectedItemId: UUID?
    @State private var selectedItemIds: Set<UUID> = [] // Multi-selection support
    
    @FocusState private var isSearchFocused: Bool
    @FocusState private var focusedRowId: UUID?
    @FocusState private var isViewFocused: Bool // For keyboard shortcuts

    var closePopover: () -> Void = {}
    var openPreferences: () -> Void = {}

    private var filteredHistory: [ClipboardItem] {
        let filtered = searchText.isEmpty ? clipboardManager.history :
            clipboardManager.history.filter { $0.previewText.localizedCaseInsensitiveContains(searchText) }
        return filtered.sorted {
            if $0.isPinned != $1.isPinned { return $0.isPinned }
            return $0.dateAdded > $1.dateAdded
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            // Main Content Panel
            VStack(spacing: 0) {
                ToolbarView(
                    itemCount: clipboardManager.history.count,
                    isSidebarVisible: $showMetadata,
                    openPreferences: openPreferences
                )
                
                SearchBarView(searchText: $searchText, isSearchFocused: $isSearchFocused, onArrowDown: {
                    if let firstId = filteredHistory.first?.id {
                        selectedItemId = firstId
                        focusedRowId = firstId
                        isSearchFocused = false
                    }
                })

                if filteredHistory.isEmpty {
                    EmptyStateView(searchText: searchText)
                } else {
                    HistoryListView(
                        history: filteredHistory,
                        selectedItemId: $selectedItemId,
                        focusedRowId: $focusedRowId,
                        clipboardManager: clipboardManager,
                        onItemClick: { item in
                            // Clear multi-selection on regular click
                            selectedItemIds.removeAll()
                            selectedItemId = item.id
                            focusedRowId = item.id
                            // Only copy to clipboard, don't move to top
                            clipboardManager.copyItemToClipboard(item: item)
                            closePopover()
                        },
                        onItemShiftClick: { item in
                            handleShiftClick(item: item)
                        },
                        selectedItemIds: $selectedItemIds,
                        moveSelection: moveSelection
                    )
                    .contextMenu {
                        // Multi-selection context menu
                        if !selectedItemIds.isEmpty {
                            Button("Delete \(selectedItemIds.count) Items", role: .destructive) {
                                clipboardManager.deleteItems(with: selectedItemIds)
                                selectedItemIds.removeAll()
                            }
                        }
                    }
                }
                
                FooterView(
                    itemCount: clipboardManager.history.count,
                    clearAction: clipboardManager.clearHistory,
                    quitAction: { NSApplication.shared.terminate(nil) }
                )
            }
            .frame(width: 320)
            // Removed solid background to allow glass effect to show through

            // Sidebar Panel - Keep persistent to avoid expensive creation/destruction
            MetadataView(
                item: selectedItemId != nil && filteredHistory.contains(where: { $0.id == selectedItemId }) 
                    ? filteredHistory.first(where: { $0.id == selectedItemId })!
                    : filteredHistory.first ?? ClipboardItem.placeholder,
                manager: clipboardManager
            )
            .frame(width: showMetadata ? 280 : 0)
            .opacity(showMetadata ? 1 : 0)
            .clipped() // Prevent content from showing outside the collapsed frame
            .transition(
                .asymmetric(
                    insertion: .slide.combined(with: .scale(scale: 0.95, anchor: .leading)),
                    removal: .slide.combined(with: .scale(scale: 0.95, anchor: .leading))
                )
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // Removed .fixedSize() to prevent layout performance issues
        .glassEffect()
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(color: DesignSystem.Shadow.medium.color, radius: DesignSystem.Shadow.medium.radius, x: DesignSystem.Shadow.medium.x, y: DesignSystem.Shadow.medium.y)
        .focusable() // Make the view focusable for keyboard shortcuts
        .focused($isViewFocused)
        .focusEffectDisabled() // Hide the focus ring
        .onAppear {
            setupInitialState()
            // Delay focus to ensure view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isViewFocused = true
            }
        }
        .onChange(of: clipboardManager.history) { _, _ in syncSelection() }
        .onChange(of: searchText) { _, _ in syncSelection() }
        .onKeyPress(.return) { copySelectedAndClose(); return .handled }
        .onKeyPress(.escape) { closePopover(); return .handled }
        .onDeleteCommand { deleteSelectedItems() } // Use dedicated delete command
        .background {
            // Hidden buttons for keyboard shortcuts that need modifiers
            VStack {
                Button("") { selectAllItems() }
                    .keyboardShortcut("a", modifiers: .command) // Changed to Cmd+A
                    .hidden()
            }
        }
    }

    // MARK: - Core Logic
    
    private func setupInitialState() {
        DispatchQueue.main.async {
            isSearchFocused = true
            let firstId = filteredHistory.first?.id
            selectedItemId = firstId
            focusedRowId = firstId
        }
    }

    private func moveSelection(_ offset: Int) {
        guard let currentId = selectedItemId,
              let idx = filteredHistory.firstIndex(where: { $0.id == currentId }) else {
            let firstId = filteredHistory.first?.id
            selectedItemId = firstId
            focusedRowId = firstId
            return
        }
        let newIdx = min(max(0, idx + offset), filteredHistory.count - 1)
        let newId = filteredHistory[newIdx].id
        selectedItemId = newId
        focusedRowId = newId
    }

    private func syncSelection() {
        if let selected = selectedItemId, !filteredHistory.contains(where: { $0.id == selected }) {
            let firstId = filteredHistory.first?.id
            selectedItemId = firstId
            focusedRowId = firstId
        } else if selectedItemId == nil, let firstId = filteredHistory.first?.id {
            selectedItemId = firstId
            focusedRowId = firstId
        }
    }

    private func copySelectedAndClose() {
        guard let selectedId = selectedItemId,
              let selected = filteredHistory.first(where: { $0.id == selectedId }) else { return }
        // Use the method that moves to top for keyboard shortcut
        clipboardManager.copyItemToClipboardAndMoveToTop(item: selected)
        closePopover()
    }
    
    private func deleteSelectedItems() {
        if selectedItemIds.isEmpty {
            // If no multi-selection, delete the currently selected item
            if let selectedId = selectedItemId {
                clipboardManager.deleteItem(with: selectedId)
            }
        } else {
            // Delete all selected items
            clipboardManager.deleteItems(with: selectedItemIds)
            selectedItemIds.removeAll()
        }
    }
    
    private func selectAllItems() {
        selectedItemIds = Set(filteredHistory.map { $0.id })
    }
    
    private func handleShiftClick(item: ClipboardItem) {
        if let lastSelectedId = selectedItemId,
           let lastIndex = filteredHistory.firstIndex(where: { $0.id == lastSelectedId }),
           let currentIndex = filteredHistory.firstIndex(where: { $0.id == item.id }) {
            
            let range = min(lastIndex, currentIndex)...max(lastIndex, currentIndex)
            let itemsInRange = Array(filteredHistory[range])
            selectedItemIds = Set(itemsInRange.map { $0.id })
        } else {
            selectedItemIds.insert(item.id)
        }
        selectedItemId = item.id
        focusedRowId = item.id
    }
}

// MARK: - Child Views (Restored and correctly placed within the file)

private struct ToolbarView: View {
    @Environment(PreferencesManager.self) private var preferencesManager
    let itemCount: Int
    @Binding var isSidebarVisible: Bool
    let openPreferences: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(preferencesManager.currentAccentColor)
                Text("PopStash")
                    .font(DesignSystem.Typography.bodyBold)
                if preferencesManager.showItemCount && itemCount > 0 {
                    Text("\(itemCount)")
                        .font(DesignSystem.Typography.mono)
                        .foregroundStyle(preferencesManager.currentAccentColor)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(DesignSystem.Materials.regular, in: Capsule())
                        .overlay(Capsule().strokeBorder(preferencesManager.currentAccentColor.opacity(0.3), lineWidth: 1))
                }
            }
            Spacer()
            HStack(spacing: DesignSystem.Spacing.sm) {
                ToolbarButton(systemName: "gearshape.fill", help: "Preferences", action: openPreferences)
                ToolbarButton(systemName: "sidebar.right", help: "Toggle Sidebar (I)", foregroundColor: isSidebarVisible ? preferencesManager.currentAccentColor : .gray.opacity(0.7)) {
                    withAnimation(.bouncy(duration: 0.4)) {
                        isSidebarVisible.toggle()
                    }
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .glassEffect(in: Rectangle())
    }
}

private struct ToolbarButton: View {
    let systemName: String
    let help: String
    var foregroundColor: Color = DesignSystem.Colors.textSecondary
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundStyle(foregroundColor)
        }
        .buttonStyle(IconButtonStyle())
        .help(help)
    }
}

private struct SearchBarView: View {
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
    let onArrowDown: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.Colors.textTertiary)
            TextField("Search clipboard...", text: $searchText)
                .textFieldStyle(.plain)
                .focused(isSearchFocused)
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.sm - 2)
        .background(DesignSystem.Materials.ultraThin, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
        .padding(DesignSystem.Spacing.sm)
        .onKeyPress(.downArrow) {
            onArrowDown()
            return .handled
        }
    }
}

private struct EmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack {
            Spacer()
            Text(searchText.isEmpty ? "Your clipboard is empty." : "No results found.")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct HistoryListView: View {
    let history: [ClipboardItem]
    @Binding var selectedItemId: UUID?
    var focusedRowId: FocusState<UUID?>.Binding
    let clipboardManager: ClipboardManager
    let onItemClick: (ClipboardItem) -> Void
    let onItemShiftClick: (ClipboardItem) -> Void
    @Binding var selectedItemIds: Set<UUID>
    let moveSelection: (Int) -> Void

    var body: some View {
        List { // Removed selection binding to eliminate blue highlighting
            ForEach(history) { item in
                ClipboardRowView(
                    item: item,
                    index: history.firstIndex(of: item) ?? 0,
                    isSelected: selectedItemId == item.id,
                    isMultiSelected: selectedItemIds.contains(item.id),
                    clipboardManager: clipboardManager,
                    onItemClick: { onItemClick(item) },
                    onItemShiftClick: { onItemShiftClick(item) },
                    focusedRowId: focusedRowId.wrappedValue // Pass the actual UUID? value
                )
                .tag(item.id)
                .focused(focusedRowId, equals: item.id)
                .listRowBackground(Color.clear) // Remove List's built-in selection background
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .frame(maxHeight: .infinity)
        .onKeyPress(.upArrow) { 
            if NSEvent.modifierFlags.contains(.shift) {
                // Shift+Up: Extend selection
                extendSelectionUp()
            } else {
                moveSelection(-1)
            }
            return .handled 
        }
        .onKeyPress(.downArrow) { 
            if NSEvent.modifierFlags.contains(.shift) {
                // Shift+Down: Extend selection  
                extendSelectionDown()
            } else {
                moveSelection(1)
            }
            return .handled 
        }
    }
    
    private func extendSelectionUp() {
        guard let currentId = selectedItemId,
              let currentIndex = history.firstIndex(where: { $0.id == currentId }),
              currentIndex > 0 else { return }
        
        let newIndex = currentIndex - 1
        let newId = history[newIndex].id
        selectedItemIds.insert(newId)
        selectedItemId = newId
        focusedRowId.wrappedValue = newId
    }
    
    private func extendSelectionDown() {
        guard let currentId = selectedItemId,
              let currentIndex = history.firstIndex(where: { $0.id == currentId }),
              currentIndex < history.count - 1 else { return }
        
        let newIndex = currentIndex + 1
        let newId = history[newIndex].id
        selectedItemIds.insert(newId)
        selectedItemId = newId
        focusedRowId.wrappedValue = newId
    }
}

private struct ClipboardRowView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let isMultiSelected: Bool
    let clipboardManager: ClipboardManager
    let onItemClick: () -> Void
    let onItemShiftClick: () -> Void
    let focusedRowId: UUID? // Add focusedRowId parameter back
    @Environment(PreferencesManager.self) private var preferencesManager
    
    @State private var isHovering = false
    
    private var backgroundStyle: AnyShapeStyle {
        if isHovering, case .text = item.content {
            return AnyShapeStyle(Color.primary.opacity(0.3))
        }
        if isMultiSelected {
            return AnyShapeStyle(preferencesManager.currentAccentColor.opacity(0.15)) // Lighter multi-select
        } else if isSelected {
            return AnyShapeStyle(preferencesManager.currentAccentColor.opacity(0.1)) // Light base selection
        } else {
            return AnyShapeStyle(Color.clear)
        }
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Button(action: {
                if NSEvent.modifierFlags.contains(.shift) {
                    // Shift+click: Multi-select
                    onItemShiftClick()
                } else if NSEvent.modifierFlags.contains(.option) {
                    // Option+click: Open in PopEditor (text items only)
                    if case .text = item.content {
                        clipboardManager.openEditorWith(item: item)
                    }
                } else {
                    // Regular click: Copy to clipboard
                    onItemClick()
                }
            }) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "doc.text")
                        .font(DesignSystem.Typography.subheadline)
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .frame(width: 14)
                    ClipboardItemContentView(item: item, isSelected: isSelected)
                    Spacer()
                    
                    // Show Option+click hint for text items when hovering
                    if isHovering {
                        Text("⌥+click to edit")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.background.opacity(0.8), in: Capsule())
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }
                    
                    ShortcutView(index: index, isSelected: isSelected)
                }
                .contentShape(Rectangle()) // Make entire area clickable
            }
            .buttonStyle(PressableButtonStyle()) // Use design system press animation
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                }
            }
            PinButton(item: item, isSelected: isSelected, clipboardManager: clipboardManager)
        }
        .background(Color.clear)
        .contentShape(Rectangle())
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            backgroundStyle, in: Rectangle()
        )
        .overlay(alignment: .bottom) {
             Rectangle()
                .fill(DesignSystem.Colors.border)
                .frame(height: 0.5)
                .padding(.leading, 30)
        }
        .overlay(
            Rectangle()
                .stroke(preferencesManager.currentAccentColor, lineWidth: 1)
                .opacity(focusedRowId == item.id ? 1.0 : 0.0) // Focus ring for keyboard navigation
        )
        .contextMenu {
            // Primary action - Copy to clipboard
            Button("Copy to Clipboard") {
                clipboardManager.copyItemToClipboard(item: item)
            }
            
            Divider()
            
            // Pin/Unpin toggle
            Button(item.isPinned ? "Unpin Item" : "Pin Item") {
                clipboardManager.togglePin(for: item)
            }
            
            // Edit in PopEditor
            if case .text = item.content {
                Button("Edit in PopEditor") {
                    clipboardManager.openEditorWith(item: item)
                }
            }
            
            Divider()
            
            // Delete item
            Button("Delete Item", role: .destructive) {
                clipboardManager.deleteItem(with: item.id)
            }
        }
    }
}

private struct ClipboardItemContentView: View {
    let item: ClipboardItem
    let isSelected: Bool

    var body: some View {
        switch item.content {
        case .text(let text):
            Text(text)
                .lineLimit(1)
                .truncationMode(.tail)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(isSelected ? .white : DesignSystem.Colors.textPrimary)
        case .image:
            if let nsImage = item.image {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 16, height: 16)
                    .clipped()
                    .cornerRadius(DesignSystem.CornerRadius.sm)
            } else {
                Text("Invalid Image")
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : DesignSystem.Colors.textSecondary)
            }
        }
    }
}

private struct ShortcutView: View {
    let index: Int
    let isSelected: Bool

    var body: some View {
        if index < 9 {
            Text("⌥\(index + 1)")
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(isSelected ? .white.opacity(0.7) : DesignSystem.Colors.textTertiary)
        }
    }
}

private struct PinButton: View {
    let item: ClipboardItem
    let isSelected: Bool
    let clipboardManager: ClipboardManager
    @Environment(PreferencesManager.self) private var preferencesManager

    var body: some View {
        Button(action: { clipboardManager.togglePin(for: item) }) {
            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(isSelected ? .white : (item.isPinned ? preferencesManager.currentAccentColor : DesignSystem.Colors.textSecondary))
                .frame(width: 20, height: 20)
        }
        .buttonStyle(.plain)
        .help(item.isPinned ? "Unpin item" : "Pin item")
    }
}

private struct FooterView: View {
    let itemCount: Int
    let clearAction: () -> Void
    let quitAction: () -> Void

    var body: some View {
        HStack {
            Text("\(itemCount) items")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
            Button("Clear", action: clearAction).buttonStyle(.link).font(DesignSystem.Typography.caption)
            Button("Quit", action: quitAction).buttonStyle(.link).font(DesignSystem.Typography.caption)
        }
        .padding(DesignSystem.Spacing.md)
        // Changed from solid background to glass effect
        .glassEffect()
    }
}
