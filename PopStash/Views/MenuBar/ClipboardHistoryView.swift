import SwiftUI

// MARK: - Main View

struct ClipboardHistoryView: View {
    @Environment(ClipboardManager.self) private var clipboardManager
    @Environment(PreferencesManager.self) private var preferencesManager

    @Binding var showMetadata: Bool
    @State private var searchText = ""
    @State private var selectedItemId: UUID?
    
    @FocusState private var isSearchFocused: Bool
    @FocusState private var focusedRowId: UUID?

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
                            selectedItemId = item.id
                            focusedRowId = item.id
                            clipboardManager.copyItemToClipboard(item: item)
                            closePopover()
                        },
                        moveSelection: moveSelection
                    )
                }
                
                FooterView(
                    itemCount: clipboardManager.history.count,
                    clearAction: clipboardManager.clearHistory,
                    quitAction: { NSApplication.shared.terminate(nil) }
                )
            }
            .frame(width: 320)
            .background(DesignSystem.Colors.backgroundSecondary)

            // Sidebar Panel
            if showMetadata {
                // Ensure there's a valid item to pass to the MetadataView
                if let selectedId = selectedItemId, let selectedItem = filteredHistory.first(where: { $0.id == selectedId }) {
                    MetadataView(item: selectedItem, manager: clipboardManager)
                        .frame(width: 280)
                        .transition(.asymmetric(insertion: .scale(scale: 0.001, anchor: .leading).combined(with: .opacity), removal: .scale(scale: 0.001, anchor: .leading).combined(with: .opacity)))
                } else if let firstItem = filteredHistory.first {
                     MetadataView(item: firstItem, manager: clipboardManager)
                        .frame(width: 280)
                        .transition(.asymmetric(insertion: .scale(scale: 0.001, anchor: .leading).combined(with: .opacity), removal: .scale(scale: 0.001, anchor: .leading).combined(with: .opacity)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize()
        .glassEffect()
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .shadow(color: DesignSystem.Shadow.medium.color, radius: DesignSystem.Shadow.medium.radius, x: DesignSystem.Shadow.medium.x, y: DesignSystem.Shadow.medium.y)
        .onAppear(perform: setupInitialState)
        .onChange(of: clipboardManager.history) { _, _ in syncSelection() }
        .onChange(of: searchText) { _, _ in syncSelection() }
        .onKeyPress(.return) { copySelectedAndClose(); return .handled }
        .onKeyPress(.escape) { closePopover(); return .handled }
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
        clipboardManager.copyItemToClipboard(item: selected)
        closePopover()
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
                    withAnimation(DesignSystem.Animation.bouncy) {
                        isSidebarVisible.toggle()
                    }
                }
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.lg)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Materials.ultraThin)
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
        .background(DesignSystem.Colors.background, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
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
    let moveSelection: (Int) -> Void

    var body: some View {
        List(selection: $selectedItemId) {
            ForEach(history) { item in
                ClipboardRowView(
                    item: item,
                    index: history.firstIndex(of: item) ?? 0,
                    isSelected: selectedItemId == item.id,
                    clipboardManager: clipboardManager,
                    onItemClick: { onItemClick(item) }
                )
                .tag(item.id)
                .focused(focusedRowId, equals: item.id)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
            }
        }
        .listStyle(.plain)
        .scrollIndicators(.hidden)
        .frame(maxHeight: .infinity)
        .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
        .onKeyPress(.downArrow) { moveSelection(1); return .handled }
    }
}

private struct ClipboardRowView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let clipboardManager: ClipboardManager
    let onItemClick: () -> Void
    @Environment(PreferencesManager.self) private var preferencesManager

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                Image(systemName: "doc.text")
                    .font(DesignSystem.Typography.subheadline)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
                    .frame(width: 14)
                ClipboardItemContentView(item: item, isSelected: isSelected)
                Spacer()
                ShortcutView(index: index, isSelected: isSelected)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onItemClick)
            PinButton(item: item, isSelected: isSelected, clipboardManager: clipboardManager)
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            isSelected ? AnyShapeStyle(preferencesManager.currentAccentColor.gradient) : AnyShapeStyle(Color.clear)
        , in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        .overlay(alignment: .bottom) {
             Rectangle()
                .fill(DesignSystem.Colors.border)
                .frame(height: 0.5)
                .padding(.leading, 30)
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
        .background(DesignSystem.Materials.ultraThin)
    }
}
