// ClipboardHistoryView.swift
import SwiftUI

// Clipboard row view for individual items
struct ClipboardRowView: View {
    let item: ClipboardItem
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 24, height: 24)
                .foregroundStyle(.tint)

            VStack(alignment: .leading, spacing: 3) {
                switch item.content {
                case .text(let text):
                    Text(text)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.primary)
                case .image:
                    if let nsImage = item.image {
                        Image(nsImage: nsImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 50, height: 28)
                            .clipped()
                            .cornerRadius(6)
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
                Text("⌥\(index + 1)")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }

            if item.isPinned {
                Image(systemName: "pin.fill")
                    .foregroundStyle(.tint)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.leading, 4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.accentColor.opacity(item.isPinned ? 0.13 : 0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(item.isPinned ? Color.accentColor : Color.clear, lineWidth: item.isPinned ? 1.5 : 0)
        )
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
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

    var body: some View {
        VStack(spacing: 0) {
            // Clipboard toolbar
            HStack(spacing: 12) {
                // Title and count
                HStack(spacing: 8) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.tint)
                        .symbolEffect(.pulse.wholeSymbol, options: .speed(0.8).repeat(.continuous))

                    Text("PopStash")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary);                    if preferencesManager.showItemCount && clipboardManager.history.count > 0 {
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


            // Clipboard search bar
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
                            Button(action: {
                                clipboardManager.copyItemToClipboard(item: item)
                            }) {
                                ClipboardRowView(item: item, index: index)
                            }
                            .tag(item.id)
                            .contextMenu {
                                Button(action: { /* Quick Look will go here */ }) {
                                    Label("Quick Look", systemImage: "eye")
                                }
                                .keyboardShortcut("q", modifiers: .option)

                                Button(action: { clipboardManager.togglePin(for: item) }) {
                                    Label(item.isPinned ? "Unpin" : "Pin", systemImage: "pin")
                                }
                                Button(role: .destructive, action: { clipboardManager.deleteItem(with: item.id) }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .buttonStyle(PopButtonStyle())
                            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: clipboardManager.history)
                            .accessibilityLabel(item.previewText)
                            .accessibilityHint(item.isPinned ? "Pinned clipboard item" : "Clipboard item")
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .frame(maxHeight: 400)
            }

            Spacer(minLength: 0)

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
