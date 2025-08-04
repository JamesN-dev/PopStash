// ClipboardHistoryView.swift
import SwiftUI

// Clipboard row view for individual items - Finder-style design
struct ClipboardRowView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    let clipboardManager: ClipboardManager
    let onItemClick: () -> Void

    private var contentView: some View {
        Group {
            switch item.content {
            case .text(let text):
                Text(text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(isSelected ? .white : .primary)
            case .image:
                if let nsImage = item.image {
                    Image(nsImage: nsImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 16, height: 16)
                        .clipped()
                        .cornerRadius(2)
                } else {
                    Text("Invalid Image")
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                        .font(.system(size: 13))
                }
            }
        }
    }

    private var shortcutView: some View {
        Group {
            if index < 9 {
                Text("⌥\(index + 1)")
                    .foregroundStyle(isSelected ? .white.opacity(0.7) : .secondary.opacity(0.6))
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
            }
        }
    }

    private var pinButton: some View {
        Button(action: {
            clipboardManager.togglePin(for: item)
        }) {
            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                .foregroundStyle(pinButtonColor)
                .font(.system(size: 9, weight: .medium))
        }
        .buttonStyle(.plain)
        .frame(width: 20, height: 20) // Slightly larger clickable area
        .contentShape(Rectangle())
        .help(item.isPinned ? "Unpin item" : "Pin item")
    }
    
    private var pinButtonColor: Color {
        if isSelected {
            return .white.opacity(0.8)
        } else if item.isPinned {
            return .accentColor
        } else {
            return .secondary.opacity(0.5)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                // Main clickable area (everything except pin button)
                HStack(spacing: 6) {
                    // Document icon
                    Image(systemName: "doc.text")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 14)

                    // Content
                    contentView

                    Spacer()

                    // Keyboard shortcut
                    shortcutView
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    onItemClick()
                }

                // Pin button (separate, non-conflicting area)
                pinButton
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
            
            // Divider line
            if index < 999 {
                Rectangle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(height: 0.5)
                    .padding(.leading, 28)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(item.previewText)
        .accessibilityHint(item.isPinned ? "Pinned clipboard item" : "Clipboard item")
    }
}

// Clipboard history view for MenuBarExtra
struct ClipboardHistoryView: View {
    @Environment(ClipboardManager.self) private var clipboardManager
    @Environment(PreferencesManager.self) private var preferencesManager
    @State private var searchText = ""
    @State private var selectedItemId: UUID?
    @State private var showingQuickLook: Bool = false
    @State private var showingSidebar: Bool = false

    var closePopover: () -> Void = {}
    var openPreferences: () -> Void = {}

    private var toolbar: some View {
        HStack(spacing: 12) {
            // Title and count
            HStack(spacing: 8) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.tint)
                    .symbolEffect(.pulse.wholeSymbol, options: .speed(0.8).repeat(.continuous))

                Text("PopStash")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.primary)

                if preferencesManager.showItemCount && clipboardManager.history.count > 0 {
                    Text("\(clipboardManager.history.count)")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundStyle(.tint)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.regularMaterial, in: Capsule())
                        .overlay(Capsule().stroke(.tint.opacity(0.3), lineWidth: 0.5))
                }
            }

            Spacer()

            // Clipboard toolbar buttons
            HStack(spacing: 8) {
                // Preferences button
                Button(action: { openPreferences() }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .frame(width: 28, height: 28)
                .background(.regularMaterial, in: Circle())
                .focusEffectDisabled()
                .help("Preferences")

                // Analytics button
                Button(action: { /* TODO: Navigate to analytics view */ }) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .frame(width: 28, height: 28)
                .background(.regularMaterial, in: Circle())
                .focusEffectDisabled()
                .help("Analytics")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .background(.regularMaterial, ignoresSafeAreaEdges: .horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("PopStash toolbar")
    }

    private var searchBar: some View {
        TextField("Search clipboard...", text: $searchText)
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
    }

    private var emptyView: some View {
        VStack {
            Spacer()
            Text(searchText.isEmpty ? "Your clipboard is empty." : "No results found.")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Debug: History count = \(clipboardManager.history.count)")
                .font(.caption)
                .foregroundColor(.red)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
    }

    private var leftPanel: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredHistory, id: \.element.id) { index, item in
                        ClipboardRowView(
                            item: item,
                            index: index,
                            isSelected: selectedItemId == item.id,
                            clipboardManager: clipboardManager,
                            onItemClick: {
                                // Single click copies to clipboard
                                clipboardManager.copyItemToClipboard(item: item)
                                // Also update selection for visual feedback
                                selectedItemId = item.id
                            }
                        )
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: clipboardManager.history)
                        .accessibilityLabel(item.previewText)
                        .accessibilityHint(item.isPinned ? "Pinned clipboard item" : "Clipboard item")
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden) // Hide scrollbar to avoid pin button conflicts
            .frame(maxHeight: 400)
        }
        .frame(width: 280)
        .background(.regularMaterial)
    }

    private var rightPanel: some View {
        Group {
            if let selectedId = selectedItemId,
               let selectedItem = filteredHistory.first(where: { $0.element.id == selectedId })?.element {
                MetadataView(item: selectedItem, manager: clipboardManager)
                    .frame(width: 280)
            } else {
                VStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 32, weight: .light))
                            .foregroundStyle(.secondary)
                        Text("Select an item to view details")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .frame(width: 280)
            }
        }
    }

    private var twoPanel: some View {
        HStack(spacing: 0) {
            leftPanel

            // Divider
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 1)

            rightPanel
        }
    }

    private var footer: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(clipboardManager.history.count) items")
                    .font(.caption)
                Spacer()
                Button("Clear") { clipboardManager.clearHistory() }
                    .font(.system(size: 12))
                Button("Quit") { NSApplication.shared.terminate(nil) }
                    .font(.system(size: 12))
            }
            .padding(10)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            searchBar

            if filteredHistory.isEmpty {
                emptyView
            } else {
                twoPanel
            }

            Spacer(minLength: 0)
            footer
        }
        // Updated size constraints for wider layout
        .frame(minWidth: 600, idealWidth: 600, maxWidth: 600, minHeight: 300, idealHeight: 500, maxHeight: 600)
        // Replace glassEffect with proper SwiftUI background styling
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .focusable()
        .onKeyPress(.upArrow) {
            navigateUp()
            return .handled
        }
        .onKeyPress(.downArrow) {
            navigateDown()
            return .handled
        }
        .onKeyPress(.return) {
            copySelectedAndClose()
            return .handled
        }
        .onKeyPress(.space) {
            triggerQuickLook()
            return .handled
        }
        .onKeyPress(.escape) {
            if showingQuickLook {
                showingQuickLook = false
            } else {
                closePopover()
            }
            return .handled
        }
        .onKeyPress(.home) {
            selectFirstItem()
            return .handled
        }
        .onKeyPress(.end) {
            selectLastItem()
            return .handled
        }
        .onAppear {
            // Auto-select first item when opening MenuBar
            if selectedItemId == nil, let firstItem = filteredHistory.first {
                selectedItemId = firstItem.element.id
            }
        }
        .onChange(of: clipboardManager.history) { _, _ in
            // Update selection if current item is no longer available
            if let selectedId = selectedItemId,
               !filteredHistory.contains(where: { $0.element.id == selectedId }) {
                selectedItemId = filteredHistory.first?.element.id
            }
        }
        .onChange(of: searchText) { _, _ in
            // Update selection when search changes
            if let selectedId = selectedItemId,
               !filteredHistory.contains(where: { $0.element.id == selectedId }) {
                selectedItemId = filteredHistory.first?.element.id
            }
        }
    }

    var filteredHistory: [(index: Int, element: ClipboardItem)] {
        let filtered = searchText.isEmpty ? clipboardManager.history : clipboardManager.history.filter {
            $0.previewText.lowercased().contains(searchText.lowercased())
        }

        // Stable sorting: pinned items stay in their original relative order at the top,
        // unpinned items stay in their original relative order below
        let sorted = filtered.sorted { item1, item2 in
            // Both pinned or both unpinned - maintain original order
            if item1.isPinned == item2.isPinned {
                // Find original indices in the full history to maintain order
                let index1 = clipboardManager.history.firstIndex { $0.id == item1.id } ?? 0
                let index2 = clipboardManager.history.firstIndex { $0.id == item2.id } ?? 0
                return index1 < index2
            }
            // One pinned, one not - pinned goes first
            return item1.isPinned && !item2.isPinned
        }

        return sorted.enumerated().map { (index, element) in
            return (index: index, element: element)
        }
    }
    
    // MARK: - Keyboard Navigation Functions
    
    private func navigateUp() {
        guard !filteredHistory.isEmpty else { return }
        
        if let selectedId = selectedItemId,
           let currentIndex = filteredHistory.firstIndex(where: { $0.element.id == selectedId }) {
            let newIndex = max(0, currentIndex - 1)
            selectedItemId = filteredHistory[newIndex].element.id
        } else {
            selectedItemId = filteredHistory.first?.element.id
        }
    }
    
    private func navigateDown() {
        guard !filteredHistory.isEmpty else { return }
        
        if let selectedId = selectedItemId,
           let currentIndex = filteredHistory.firstIndex(where: { $0.element.id == selectedId }) {
            let newIndex = min(filteredHistory.count - 1, currentIndex + 1)
            selectedItemId = filteredHistory[newIndex].element.id
        } else {
            selectedItemId = filteredHistory.first?.element.id
        }
    }
    
    private func selectFirstItem() {
        selectedItemId = filteredHistory.first?.element.id
    }
    
    private func selectLastItem() {
        selectedItemId = filteredHistory.last?.element.id
    }
    
    private func copySelectedAndClose() {
        guard let selectedId = selectedItemId,
              let selectedItem = filteredHistory.first(where: { $0.element.id == selectedId })?.element else { return }
        
        clipboardManager.copyItemToClipboard(item: selectedItem)
        closePopover()
    }
    
    private func triggerQuickLook() {
        guard selectedItemId != nil else { return }
        showingQuickLook = true
        // TODO: Implement Quick Look overlay
    }
}

// This extension is required for the conditional .if modifier
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition { transform(self) } else { self }
    }
}

// The preview provider is required for the file to compile
struct ClipboardHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ClipboardHistoryView()
    }
}
