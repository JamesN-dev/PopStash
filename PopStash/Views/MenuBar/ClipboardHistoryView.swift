import SwiftUI
import AppKit

// MARK: - Main View

struct ClipboardHistoryView: View {
    @Environment(ClipboardManager.self) private var clipboardManager
    @Environment(PreferencesManager.self) private var preferencesManager

    @Binding var showMetadata: Bool
    @State private var searchText = ""
    @State private var selectedItemId: UUID?
    @State private var selectedItemIds: Set<UUID> = [] // Multi-selection support
    @State private var selectionAnchorId: UUID? // Anchor for range selections with Shift

    @FocusState private var isSearchFocused: Bool
    @FocusState private var focusedRowId: UUID?
    @FocusState private var isViewFocused: Bool // For keyboard shortcuts
    @State private var showPlainToast = false
    @State private var showCopyToast = false
    @State private var copyToastMessage = ""

    var closePopover: () -> Void = {}
    var openPreferences: () -> Void = {}

    private var filteredHistory: [ClipboardItem] {
        clipboardManager.filteredHistory(matching: searchText)
    }

    // Precompute the item to show in the MetadataView to keep body simpler
    private var selectedMetadataItem: ClipboardItem {
        if let selectedId = selectedItemId,
           let match = filteredHistory.first(where: { $0.id == selectedId }) {
            return match
        }
        return filteredHistory.first ?? ClipboardItem.placeholder
    }

    // Small handler to avoid inline closure complexity at call site
    private func handleSearchArrowDown() {
        if let firstId = filteredHistory.first?.id {
            selectedItemId = firstId
            focusedRowId = firstId
            isSearchFocused = false
        }
    }

    // Extract main panel content to help the compiler
    private var mainPanel: some View {
        VStack(spacing: 0) {
            ToolbarView(
                itemCount: clipboardManager.history.count,
                isSidebarVisible: $showMetadata,
                openPreferences: openPreferences
            )
            .contentShape(Rectangle())
            .pointerStyle(.default) // keep arrow over header/title bar (macOS 15+)

            SearchBarView(
                searchText: $searchText,
                isSearchFocused: $isSearchFocused,
                onArrowDown: handleSearchArrowDown
            )

            if filteredHistory.isEmpty {
                EmptyStateView(searchText: searchText)
            } else {
                HistoryListView(
                    history: filteredHistory,
                    selectedItemId: $selectedItemId,
                    focusedRowId: $focusedRowId,
                    selectionAnchorId: $selectionAnchorId,
                    clipboardManager: clipboardManager,
                    onItemClick: { item in
                        // Clear multi-selection on regular click
                        selectedItemIds.removeAll()
                        selectedItemId = item.id
                        selectionAnchorId = item.id
                        focusedRowId = item.id
                        // Only copy to clipboard, don't move to top
                        clipboardManager.copyItemToClipboard(item: item)
                        
                        // Show toast with appropriate message
                        if case .text = item.content {
                            copyToastMessage = "Copied as Plain Text"
                        } else {
                            copyToastMessage = "Copied"
                        }
                        withAnimation(.easeInOut(duration: 0.15)) { showCopyToast = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            withAnimation(.easeInOut(duration: 0.2)) { showCopyToast = false }
                        }
                        
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
    }

    // Extract sidebar panel using Transition API instead of manual frame/opacity
    private var sidebarPanel: some View {
        Group {
            if showMetadata {
                MetadataView(
                    item: selectedMetadataItem,
                    manager: clipboardManager
                )
                .frame(width: 280)
                .transition(preferencesManager.reduceAnimations ? .identity : AnyTransition.asymmetric(
                    insertion: DesignSystem.Transitions.topScale(0.96),
                    removal: DesignSystem.Transitions.topScale(0.98)
                ))
            }
        }
        .animation(preferencesManager.reduceAnimations ? .none : DesignSystem.Animation.smooth, value: showMetadata)
    }

    var body: some View {
        HStack(spacing: 0) {
            // Main Content Panel
            mainPanel
                .frame(width: 320)

            // Sidebar Panel - Keep persistent to avoid expensive creation/destruction
            sidebarPanel
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
            // Ensure the view and search have focus immediately so arrow keys work right away
            isViewFocused = true
            isSearchFocused = true
            setupInitialState()
            // Respect preference to keep metadata visible
            if preferencesManager.alwaysShowMetadata {
                showMetadata = true
            }
        }
        .onChange(of: clipboardManager.history) { _, _ in
            if let newestId = clipboardManager.lastAddedItemId,
               filteredHistory.contains(where: { $0.id == newestId }) {
                selectedItemId = newestId
                focusedRowId = newestId
            } else {
                // Leave selection as-is; do not force first item
                syncSelection()
            }
        }
        .onChange(of: searchText) { _, _ in
            // Avoid stealing focus from search field while typing; only sync when search not focused
            if !isSearchFocused { syncSelection() }
        }
        .onChange(of: preferencesManager.alwaysShowMetadata) { _, newValue in
            if preferencesManager.reduceAnimations {
                showMetadata = newValue
            } else {
                withAnimation(DesignSystem.Animation.smooth) {
                    showMetadata = newValue
                }
            }
        }
        .onKeyPress(.return) {
            let flags = NSEvent.modifierFlags
            if flags.contains(.option) {
                // Option+Return: copy as plain text with toast
                copySelectedAndClose(asPlainText: true)
                withAnimation(.easeInOut(duration: 0.15)) { showPlainToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.2)) { showPlainToast = false }
                }
            } else {
                // Plain Return: copy with original formatting and show toast
                if let selectedId = selectedItemId,
                   let selected = filteredHistory.first(where: { $0.id == selectedId }) {
                    if case .text = selected.content {
                        copyToastMessage = "Copied as Plain Text"
                    } else {
                        copyToastMessage = "Copied"
                    }
                    withAnimation(.easeInOut(duration: 0.15)) { showCopyToast = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        withAnimation(.easeInOut(duration: 0.2)) { showCopyToast = false }
                    }
                }
                copySelectedAndClose()
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            guard !filteredHistory.isEmpty else { return .handled }
            if isSearchFocused {
                if let firstId = filteredHistory.first?.id {
                    selectedItemId = firstId
                    focusedRowId = firstId
                    selectionAnchorId = firstId
                    isSearchFocused = false
                }
                return .handled
            }
            // Let the List handle navigation and Shift multi-select when not in search
            return .ignored
        }
        .onKeyPress(.upArrow) {
            guard !filteredHistory.isEmpty else { return .handled }
            if isSearchFocused {
                // From search, up should also enter list (to the first item)
                if let firstId = filteredHistory.first?.id {
                    selectedItemId = firstId
                    focusedRowId = firstId
                    selectionAnchorId = firstId
                    isSearchFocused = false
                }
                return .handled
            }
            // Let the List handle navigation and Shift multi-select when not in search
            return .ignored
        }
    // Option+Return for plain text is handled in the generic return handler above
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
        .overlay(alignment: .top) {
            if showPlainToast {
                Text("Copied as Plain Text")
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DesignSystem.Materials.regular, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.gray.opacity(0.4), lineWidth: 1))
                    .foregroundStyle(.secondary)
                    .transition(preferencesManager.reduceAnimations ? .identity : DesignSystem.Transitions.topDrop)
                    .padding(.top, 6)
            } else if showCopyToast {
                Text(copyToastMessage)
                    .font(.system(size: 11, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(DesignSystem.Materials.regular, in: Capsule())
                    .overlay(Capsule().strokeBorder(Color.gray.opacity(0.4), lineWidth: 1))
                    .foregroundStyle(.secondary)
                    .transition(preferencesManager.reduceAnimations ? .identity : DesignSystem.Transitions.topDrop)
                    .padding(.top, 6)
            }
        }
    }

    // MARK: - Core Logic

    private func setupInitialState() {
        // Only pre-select if there's a known last added item still visible
        if let newest = clipboardManager.lastAddedItemId,
           filteredHistory.contains(where: { $0.id == newest }) {
            selectedItemId = newest
            focusedRowId = newest
        } else {
            selectedItemId = nil
            focusedRowId = nil
        }
    }

    private func moveSelection(_ offset: Int) {
        guard let currentId = selectedItemId,
              let idx = filteredHistory.firstIndex(where: { $0.id == currentId }) else {
            let firstId = filteredHistory.first?.id
            selectedItemId = firstId
            selectionAnchorId = firstId
            selectedItemIds.removeAll()
            focusedRowId = firstId
            return
        }
        let newIdx = min(max(0, idx + offset), filteredHistory.count - 1)
        let newId = filteredHistory[newIdx].id
        selectedItemId = newId
        selectionAnchorId = newId // Reset anchor on normal arrow movement
        selectedItemIds.removeAll() // Collapse to single selection on non-shift movement
        focusedRowId = newId
    }

    private func syncSelection() {
        // If current selection vanished, prefer lastAdded; else clear selection (no auto top selection)
        if let selected = selectedItemId, !filteredHistory.contains(where: { $0.id == selected }) {
            if let newest = clipboardManager.lastAddedItemId,
               filteredHistory.contains(where: { $0.id == newest }) {
                selectedItemId = newest
                focusedRowId = newest
                selectionAnchorId = newest
            } else {
                selectedItemId = nil
                focusedRowId = nil
                selectionAnchorId = nil
            }
        }
        // If nothing selected, do not auto-select unless there's a newest id
        if selectedItemId == nil, let newest = clipboardManager.lastAddedItemId,
           filteredHistory.contains(where: { $0.id == newest }) {
            selectedItemId = newest
            focusedRowId = newest
            selectionAnchorId = newest
        }
    }

    private func copySelectedAndClose(asPlainText: Bool = false) {
        guard let selectedId = selectedItemId,
              let selected = filteredHistory.first(where: { $0.id == selectedId }) else { return }
        // Only copy to clipboard, don't move to top (consistent with click behavior)
        clipboardManager.copyItemToClipboard(item: selected, asPlainText: asPlainText)
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
        // Ensure we have an anchor; default to current selection or clicked item
        if selectionAnchorId == nil {
            selectionAnchorId = selectedItemId ?? item.id
        }
        guard let anchorId = selectionAnchorId,
              let anchorIndex = filteredHistory.firstIndex(where: { $0.id == anchorId }),
              let currentIndex = filteredHistory.firstIndex(where: { $0.id == item.id }) else {
            return
        }
        let range = min(anchorIndex, currentIndex)...max(anchorIndex, currentIndex)
        selectedItemIds = Set(filteredHistory[range].map { $0.id })
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
                    .accessibilityAddTraits(.isHeader)
                if preferencesManager.showItemCount && itemCount > 0 {
                    Text("\(itemCount)")
                        .font(DesignSystem.Typography.mono)
                        .foregroundStyle(preferencesManager.currentAccentColor)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(DesignSystem.Materials.regular, in: Capsule())
                        .overlay(Capsule().strokeBorder(preferencesManager.currentAccentColor.opacity(0.3), lineWidth: 1))
                        .accessibilityLabel("Item count: \(itemCount)")
                }
            }
            Spacer()
            HStack(spacing: DesignSystem.Spacing.sm) {
                ToolbarButton(systemName: "gearshape.fill", help: "Preferences", action: openPreferences)
                ToolbarButton(systemName: "sidebar.right", help: "Toggle Sidebar (I)", foregroundColor: isSidebarVisible ? preferencesManager.currentAccentColor : .gray.opacity(0.7)) {
                    if preferencesManager.reduceAnimations {
                        isSidebarVisible.toggle()
                    } else {
                        withAnimation(DesignSystem.Animation.smooth) {
                            isSidebarVisible.toggle()
                        }
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
    .accessibilityLabel(help)
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
                .accessibilityHidden(true)
            TextField("Search clipboard...", text: $searchText)
                .textFieldStyle(.plain)
                .focused(isSearchFocused)
                .accessibilityLabel("Search clipboard")
                .accessibilityHint("Type to filter clipboard history")
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
    @Binding var selectionAnchorId: UUID?
    let clipboardManager: ClipboardManager
    let onItemClick: (ClipboardItem) -> Void
    let onItemShiftClick: (ClipboardItem) -> Void
    @Binding var selectedItemIds: Set<UUID>
    let moveSelection: (Int) -> Void

    var body: some View {
        List {
            ForEach(Array(history.enumerated()), id: \.element.id) { index, item in
                ClipboardRowView(
                    item: item,
                    index: index,
                    isSelected: selectedItemId == item.id,
                    isMultiSelected: selectedItemIds.contains(item.id),
                    clipboardManager: clipboardManager,
                    onItemClick: { onItemClick(item) },
                    onItemShiftClick: { onItemShiftClick(item) },
                    focusedRowId: focusedRowId.wrappedValue
                )
                .tag(item.id)
                .focused(focusedRowId, equals: item.id)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .padding(.top, 2)
        .frame(maxHeight: .infinity)
        // .animation(nil, value: history)
        .onKeyPress(.upArrow) {
            if NSEvent.modifierFlags.contains(.shift) {
                extendSelection(by: -1)
            } else {
                moveSelection(-1)
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            if NSEvent.modifierFlags.contains(.shift) {
                extendSelection(by: 1)
            } else {
                moveSelection(1)
            }
            return .handled
        }
    }

    private func extendSelection(by delta: Int) {
        guard !history.isEmpty else { return }
        // Ensure we have a current selection; if not, start at first row
        if selectedItemId == nil {
            selectedItemId = history.first?.id
            selectionAnchorId = selectedItemId
        }
        guard let currentId = selectedItemId,
              let currentIndex = history.firstIndex(where: { $0.id == currentId }) else { return }

        let nextIndex = min(max(0, currentIndex + delta), history.count - 1)
        if selectionAnchorId == nil { selectionAnchorId = currentId }
        guard let anchorId = selectionAnchorId,
              let anchorIndex = history.firstIndex(where: { $0.id == anchorId }) else { return }

        let lower = min(anchorIndex, nextIndex)
        let upper = max(anchorIndex, nextIndex)
        selectedItemIds = Set(history[lower...upper].map { $0.id })
        let newId = history[nextIndex].id
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

    // Primary icon should prefer the original source; fallback to current; then doc
    private var primaryAppIcon: NSImage {
        if let bundleID = item.originalSourceAppBundleID ?? item.sourceAppBundleID,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: appURL.path)
        }
        return NSImage(systemSymbolName: "doc", accessibilityDescription: "Default Icon") ?? NSImage()
    }

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
                    Image(nsImage: primaryAppIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 14, height: 14)
                    ClipboardItemContentView(item: item, isSelected: isSelected)
                    Spacer()

                    // Show Option+click hint for text items when hovering
                    if isHovering && preferencesManager.showOptionClickHint {
                        Text("⌥+click to edit")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(DesignSystem.Colors.textTertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(DesignSystem.Colors.background.opacity(0.8), in: Capsule())
                            .transition(.opacity.combined(with: .scale(scale: 0.9)))
                    }

                    // Option+click hint removed shortcut display since Option+1-9 shortcuts were removed
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
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item.previewText.isEmpty ? "Clipboard item" : item.previewText)
        .accessibilityValue(item.isPinned ? "Pinned" : "Unpinned")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityActions {
            Button(item.isPinned ? "Unpin" : "Pin") { clipboardManager.togglePin(for: item) }
            Button("Copy") { clipboardManager.copyItemToClipboard(item: item) }
            if case .text = item.content {
                Button("Edit") { clipboardManager.openEditorWith(item: item) }
            }
        }
        .contextMenu {
            // Primary action - Copy to clipboard
            Button("Copy to Clipboard") {
                clipboardManager.copyItemToClipboard(item: item)
            }

            Button("Copy as Plain Text") {
                clipboardManager.copyItemToClipboard(item: item, asPlainText: true)
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

// ShortcutView removed - Option+1-9 shortcuts were not great shortcuts

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
