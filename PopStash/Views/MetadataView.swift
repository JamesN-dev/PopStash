import SwiftUI

struct MetadataView: View {
    let item: ClipboardItem
    let manager: ClipboardManager
    @Environment(PreferencesManager.self) private var preferences

    @State private var selectedTab: Tab = .preview

    enum Tab: String, CaseIterable, Identifiable {
        case preview = "Preview"
        case details = "Details"
        case actions = "Actions"

        var id: String { self.rawValue }

        var systemImage: String {
            switch self {
            case .preview: "eye"
            case .details: "info.circle"
            case .actions: "hammer"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Meta text as toolbar header
            HStack(spacing: 8) {
                // Per-item chip (type)
                if case .text = item.content {
                    Text("Plain")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DesignSystem.Materials.regular, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.gray.opacity(0.4), lineWidth: 1))
                        .foregroundStyle(.secondary)
                        .help("This item is text (plain). Rich planned for future.")
                } else {
                    Text("Image")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DesignSystem.Materials.regular, in: Capsule())
                        .overlay(Capsule().strokeBorder(Color.gray.opacity(0.4), lineWidth: 1))
                        .foregroundStyle(.secondary)
                        .help("This item is an image.")
                }

                Text("Meta")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                // Default-mode chip on the right (what Return will do)
                if case .text = item.content {
                    let isPlain = preferences.pasteAsPlainTextByDefault
                    Text(isPlain ? "Default: Plain" : "Default: Rich")
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(DesignSystem.Materials.regular, in: Capsule())
                        .overlay(
                            Capsule().strokeBorder(
                                (isPlain ? Color.gray.opacity(0.5) : Color.accentColor.opacity(0.5)),
                                lineWidth: 1
                            )
                        )
                        .foregroundStyle(isPlain ? .secondary : Color.accentColor)
                        .help("Press Return to copy using the default mode. Option+Return copies as Plain.")
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md + 2)
            .glassEffect(in: Rectangle())

            Divider()

            // Tabs section
            HStack(spacing: 4) {
                ForEach(Tab.allCases) { tab in
                    tabButton(for: tab)
                }
            }
            .padding(DesignSystem.Spacing.xs)
            .glassEffect(in: Rectangle())

            Divider()
            contentView
        }
        .glassEffect()
    }

    // MARK: - Subviews

    private func tabButton(for tab: Tab) -> some View {
        Button(action: { selectedTab = tab }) {
            VStack(spacing: 2) {
                Image(systemName: tab.systemImage)
                    .font(.system(size: 14, weight: .medium))
                Text(tab.rawValue)
                    .font(.system(size: 10, weight: .medium))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle()) // Improves hitbox
            .background(
                selectedTab == tab ?
                AnyShapeStyle(DesignSystem.Materials.regular) :
                AnyShapeStyle(Color.clear),
                in: RoundedRectangle(cornerRadius: 6)
            )
            .overlay(
                selectedTab == tab ?
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1) :
                nil
            )
            .foregroundStyle(
                selectedTab == tab ? Color.accentColor : Color.secondary
            )
        }
        .buttonStyle(PressableButtonStyle()) // Use design system press animation
    }

    private var contentView: some View {
        Group {
            switch selectedTab {
            case .preview:
                PreviewTabView(item: item)
            case .details:
                DetailsTabView(item: item)
            case .actions:
                ActionsTabView(item: item, manager: manager)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// ... (Rest of the MetadataView subviews are in DesignSystem)
