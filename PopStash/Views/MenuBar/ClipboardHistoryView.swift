// ClipboardHistoryView.swift
import SwiftUI

// This is the dedicated View for a single row in the list.
struct ClipboardRowView: View {
    let item: ClipboardItem
    let index: Int

    private var sourceAppIcon: NSImage {
        guard let bundleID = item.sourceAppBundleID,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return NSImage(systemSymbolName: "doc", accessibilityDescription: "Default Icon")!
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: sourceAppIcon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                switch item.content {
                case .text(let text):
                    Text(text)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                case .image:
                    if let nsImage = item.image {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 28)
                            .clipped()
                            .cornerRadius(4)
                    } else {
                        Text("Invalid Image")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer()

            if index < 9 {
                Text("⌘\(index + 1)")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))
            }

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundColor(Color(NSColor.controlAccentColor))
                    .font(.system(size: 11))
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
    }
}

// This is the main view for the popover.
struct ClipboardHistoryView: View {
    @Environment(ClipboardManager.self) private var clipboardManager
    @State private var searchText = ""
    @State private var selectedItemId: UUID?

    var closePopover: () -> Void = {}
    var openPreferences: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search clipboard...", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

            if filteredHistory.isEmpty {
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
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(filteredHistory, id: \.element.id) { index, item in
                            ClipboardRowView(item: item, index: index)
                                .tag(item.id)
                                .contextMenu {
                                    Button(action: { /* Quick Look will go here */ }) {
                                        Label("Quick Look", systemImage: "eye")
                                    }
                                    .keyboardShortcut("q", modifiers: .option)
                                    
                                    Divider()

                                    Button(action: { clipboardManager.togglePin(for: item) }) {
                                        Label(item.isPinned ? "Unpin" : "Pin", systemImage: "pin")
                                    }
                                    
                                    Button(role: .destructive, action: { clipboardManager.deleteItem(with: item.id) }) {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .onTapGesture {
                                    clipboardManager.copyItemToClipboard(item: item)
                                }
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 400)
            }

            Spacer(minLength: 0)

            VStack(spacing: 0) {
                Divider()
                HStack {
                    Text("\(clipboardManager.history.count) items")
                        .font(.caption)
                    Spacer()
                    Button("Preferences…") { openPreferences() }
                        .font(.system(size: 12))
                    Button("Clear") { clipboardManager.clearHistory() }
                        .font(.system(size: 12))
                    Button("Quit") { NSApplication.shared.terminate(nil) }
                        .font(.system(size: 12))
                }
                .padding(10)
            }
        }
        // Keep your full size constraints
        .frame(minWidth: 400, idealWidth: 450, maxWidth: 500, minHeight: 300, idealHeight: 500, maxHeight: 600)
        // Replace glassEffect with proper SwiftUI background styling
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
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
