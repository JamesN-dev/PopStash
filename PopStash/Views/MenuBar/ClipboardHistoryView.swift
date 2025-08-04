// ClipboardHistoryView.swift
import SwiftUI

// Clipboard row view for individual items - modernized, flat design
struct ClipboardRowView: View {
    let item: ClipboardItem
    let index: Int
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)
                .frame(width: 16)

            HStack(spacing: 6) {
                switch item.content {
                case .text(let text):
                    Text(text)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.primary)
                case .image:
                    if let nsImage = item.image {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 20, height: 20)
                            .clipped()
                            .cornerRadius(3)
                    } else {
                        Text("Invalid Image")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                    }
                }
                
                Spacer()
                
                if index < 9 {
                    Text("⌥\(index + 1)")
                        .foregroundColor(.secondary)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }

                if item.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(.tint)
                        .font(.system(size: 10, weight: .medium))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Rectangle()
                .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
        )
        .contentShape(Rectangle())
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

                // Close button
                Button(action: { closePopover() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .frame(width: 28, height: 28)
                .background(.regularMaterial, in: Circle())
                .focusEffectDisabled()
                .help("Close")
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
                LazyVStack(spacing: 1) {
                    ForEach(filteredHistory, id: \.element.id) { index, item in
                        Button(action: {
                            selectedItemId = item.id
                        }) {
                            ClipboardRowView(
                                item: item, 
                                index: index,
                                isSelected: selectedItemId == item.id
                            )
                        }
                        .buttonStyle(.plain)
                        .onTapGesture(count: 2) {
                            // Double-tap to copy
                            clipboardManager.copyItemToClipboard(item: item)
                        }
                        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: clipboardManager.history)
                        .accessibilityLabel(item.previewText)
                        .accessibilityHint(item.isPinned ? "Pinned clipboard item" : "Clipboard item")
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: 400)
        }
        .frame(width: 280)
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
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            // Select first item by default
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

        let sorted = filtered.sorted { item1, item2 in
            if item1.isPinned && !item2.isPinned { return true }
            return false
        }

        return sorted.enumerated().map { (index, element) in
            return (index: index, element: element)
        }
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
