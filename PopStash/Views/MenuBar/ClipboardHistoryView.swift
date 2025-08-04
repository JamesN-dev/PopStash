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

    private var pinButtonColor: Color {
        if isSelected {
            return .white.opacity(0.8)
        } else if item.isPinned {
            return Color.accentColor
        } else {
            return .secondary.opacity(0.5)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 6) {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(width: 14)
                    contentView
                    Spacer()
                    shortcutView
                }
                .contentShape(Rectangle())
                .onTapGesture { onItemClick() }
                Button(action: {
                    clipboardManager.togglePin(for: item)
                }) {
                    Image(systemName: item.isPinned ? "pin.fill" : "pin")
                        .foregroundStyle(pinButtonColor)
                        .font(.system(size: 9, weight: .medium))
                        .frame(width: 20, height: 20)
                }
                .buttonStyle(.plain)
                .help(item.isPinned ? "Unpin item" : "Pin item")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Rectangle()
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
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

struct ClipboardHistoryView: View {
    @Environment(ClipboardManager.self) private var clipboardManager
    @Environment(PreferencesManager.self) private var preferencesManager

    @State private var searchText = ""
    @State private var selectedItemId: UUID? = nil
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
        .frame(minWidth: 600, maxWidth: 600, minHeight: 300, maxHeight: 600)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            DispatchQueue.main.async {
                isSearchFocused = true
                selectedItemId = filteredHistory.first?.id
                focusedRowId = filteredHistory.first?.id
            }
        }
        .onChange(of: clipboardManager.history) { _, _ in syncSelection() }
        .onChange(of: searchText) { _, _ in syncSelection() }
        .onKeyPress(.return) { copySelectedAndClose(); return .handled }
        .onKeyPress(.space) { triggerQuickLook(); return .handled }
        .onKeyPress(.escape) { closePopover(); return .handled }
    }

    private var toolbar: some View {
        HStack(spacing: 12) {
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
            HStack(spacing: 8) {
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
            .focused($isSearchFocused)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .onKeyPress(.downArrow) {
                if let firstId = filteredHistory.first?.id {
                    selectedItemId = firstId
                    focusedRowId = firstId
                }
                isSearchFocused = false
                return .handled
            }
    }

    private var emptyView: some View {
        VStack {
            Spacer()
            Text(searchText.isEmpty ? "Your clipboard is empty." : "No results found.")
                .font(.headline)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: 300)
    }

    private var leftPanel: some View {
        VStack(spacing: 0) {
            List(filteredHistory, id: \.id, selection: $selectedItemId) { item in
                ClipboardRowView(
                    item: item,
                    index: filteredHistory.firstIndex(of: item) ?? 0,
                    isSelected: selectedItemId == item.id,
                    clipboardManager: clipboardManager,
                    onItemClick: {
                        selectedItemId = item.id
                        focusedRowId = item.id
                        clipboardManager.copyItemToClipboard(item: item)
                        closePopover()
                    }
                )
                .tag(item.id)
                .focused($focusedRowId, equals: item.id)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .accessibilityLabel(item.previewText)
                .accessibilityHint(item.isPinned ? "Pinned clipboard item" : "Clipboard item")
            }
            .listStyle(.plain)
            .scrollIndicators(.hidden)
            .frame(maxHeight: 400)
            .onKeyPress(.upArrow) { moveSelection(-1); return .handled }
            .onKeyPress(.downArrow) { moveSelection(1); return .handled }
        }
        .frame(width: 280)
        .background(.regularMaterial)
    }

    private var rightPanel: some View {
        Group {
            if let selectedId = selectedItemId,
               let selected = filteredHistory.first(where: { $0.id == selectedId }) {
                MetadataView(item: selected, manager: clipboardManager)
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

    // MARK: - Core Logic

    private func moveSelection(_ offset: Int) {
        guard let currentId = selectedItemId,
              let idx = filteredHistory.firstIndex(where: { $0.id == currentId }) else {
            selectedItemId = filteredHistory.first?.id
            focusedRowId = filteredHistory.first?.id
            return
        }
        let newIdx = min(max(0, idx + offset), filteredHistory.count - 1)
        let newId = filteredHistory[newIdx].id
        selectedItemId = newId
        focusedRowId = newId
    }

    private func syncSelection() {
        if let selected = selectedItemId, filteredHistory.contains(where: { $0.id == selected }) {
            // Still valid, do nothing
        } else {
            selectedItemId = filteredHistory.first?.id
            focusedRowId = filteredHistory.first?.id
        }
    }

    private func copySelectedAndClose() {
        guard let selectedId = selectedItemId,
              let selected = filteredHistory.first(where: { $0.id == selectedId }) else { return }
        clipboardManager.copyItemToClipboard(item: selected)
        closePopover()
    }

    private func triggerQuickLook() {
        // Implement Quick Look overlay as needed
    }
}

// The preview provider is required for the file to compile
struct ClipboardHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ClipboardHistoryView()
    }
}
