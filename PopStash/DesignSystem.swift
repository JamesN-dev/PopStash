import SwiftUI
import AppKit

// MARK: - Professional Design System

/// A comprehensive design system that defines the visual language of the application.
struct DesignSystem {
    
    // MARK: - Color Palette
    struct Colors {
        static let primary = Color.accentColor
        static let success = Color(NSColor.systemGreen)
        static let warning = Color(NSColor.systemYellow)
        static let error = Color(NSColor.systemRed)
        static let background = Color(NSColor.windowBackgroundColor)
        static let backgroundSecondary = Color(NSColor.controlBackgroundColor)
        static let border = Color(NSColor.separatorColor)
        static let textPrimary = Color(NSColor.labelColor)
        static let textSecondary = Color(NSColor.secondaryLabelColor)
        static let textTertiary = Color(NSColor.tertiaryLabelColor)
        static let primaryGradient = LinearGradient(colors: [primary, primary.opacity(0.8)], startPoint: .top, endPoint: .bottom)
    }
    
    // MARK: - Typography System
    struct Typography {
        static let headline = Font.system(.headline).weight(.semibold)
        static let title = Font.system(.title3).weight(.medium)
        static let body = Font.system(.body)
        static let bodyBold = Font.system(.body).weight(.semibold)
        static let subheadline = Font.system(.subheadline)
        static let caption = Font.system(.caption)
        static let caption2 = Font.system(.caption2)
        static let mono = Font.system(.body, design: .monospaced)
    }
    
    // MARK: - Spacing System
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 8
        static let lg: CGFloat = 12
        static let circular: CGFloat = 1_000
    }
    
    // MARK: - Shadows
    struct Shadow {
        static let subtle = (color: Color(NSColor.shadowColor).opacity(0.15), radius: 2.0, x: 0.0, y: 1.0)
        static let medium = (color: Color(NSColor.shadowColor).opacity(0.2), radius: 5.0, x: 0.0, y: 2.0)
    }
    
    // MARK: - Animation Curves
    struct Animation {
        static let smooth = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let bouncy = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
    }
    
    // MARK: - Visual Effects
    struct Materials {
        static let regular = Material.regular
        static let thick = Material.thick
        static let ultraThin = Material.ultraThin
    }
}

// MARK: - View Extensions & Styles

extension View {
    /// Custom glass effect with backward compatibility for macOS 26
    @ViewBuilder
    func glassEffect(in shape: some Shape = Capsule(), interactive: Bool = false) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: shape)
        } else {
            self.background {
                shape.customGlassEffect()
            }
        }
    }
    
    /// Convenience method for default glass effect
    func glassEffect() -> some View {
        self.glassEffect(in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
    }
}

extension Shape {
    /// Custom glass effect implementation for pre-macOS 26
    func customGlassEffect() -> some View {
        self
            .fill(.ultraThinMaterial)
            .fill(
                .linearGradient(
                    colors: [
                        .primary.opacity(0.08),
                        .primary.opacity(0.05),
                        .primary.opacity(0.01),
                        .clear,
                        .clear,
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .stroke(.primary.opacity(0.2), lineWidth: 0.5)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .frame(width: 28, height: 28)
            .background(Color.primary.opacity(configuration.isPressed ? 0.2 : 0))
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(DesignSystem.Animation.bouncy, value: configuration.isPressed)
    }
}

struct PressableButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Reusable UI Components (Now Centralized)

// --- Components for PreferencesView ---

struct PreferencesSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text(title)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            
            VStack(spacing: DesignSystem.Spacing.md) {
                content
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Colors.background, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }
}

struct SettingRow<Control: View>: View {
    let label: String
    @ViewBuilder let control: Control
    
    var body: some View {
        HStack {
            Text(label)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(DesignSystem.Colors.textPrimary)
            Spacer()
            control
        }
    }
}

// --- Components for MetadataView ---

struct PreviewTabView: View {
    let item: ClipboardItem
    
    var body: some View {
        VStack {
            switch item.content {
            case .text(let text):
                ScrollView {
                    Text(text)
                        .font(DesignSystem.Typography.mono)
                        .textSelection(.enabled) // Make text selectable
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(DesignSystem.Spacing.md)
                }
                .background(DesignSystem.Colors.background, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                .overlay(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md).stroke(DesignSystem.Colors.border, lineWidth: 1))
                
            case .image(let data):
                if let nsImage = NSImage(data: data) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(DesignSystem.CornerRadius.md)
                        .shadow(color: DesignSystem.Shadow.subtle.color, radius: DesignSystem.Shadow.subtle.radius, x: DesignSystem.Shadow.subtle.x, y: DesignSystem.Shadow.subtle.y)

                } else {
                    ContentUnavailableView("Invalid Image", systemImage: "photo.fill")
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
    }
}

struct DetailsTabView: View {
    let item: ClipboardItem
    
    private var sourceAppIcon: NSImage {
        guard let bundleID = item.sourceAppBundleID,
              let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return NSImage(systemSymbolName: "doc", accessibilityDescription: "Default Icon")!
        }
        return NSWorkspace.shared.icon(forFile: appURL.path)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                
                MetadataSection(title: "SOURCE") {
                    HStack {
                        Image(nsImage: sourceAppIcon)
                            .resizable().aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                        Text(item.sourceAppName ?? "Unknown")
                            .font(DesignSystem.Typography.bodyBold)
                    }
                }
                
                MetadataSection(title: "TIMESTAMPS") {
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        MetadataRow(label: "Date Copied", value: item.dateAdded, format: .abbreviated)
                        MetadataRow(label: "Time Copied", value: item.dateAdded, format: .standard)
                    }
                }
                
                if case .text(let text) = item.content {
                    MetadataSection(title: "TEXT DETAILS") {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            MetadataRow(label: "Characters", value: "\(text.count)")
                            MetadataRow(label: "Words", value: "\(text.split(whereSeparator: \.isWhitespace).count)")
                        }
                    }
                } else if case .image(let data) = item.content, let nsImage = NSImage(data: data) {
                     MetadataSection(title: "IMAGE DETAILS") {
                        VStack(spacing: DesignSystem.Spacing.sm) {
                            MetadataRow(label: "Dimensions", value: "\(Int(nsImage.size.width)) x \(Int(nsImage.size.height))")
                            MetadataRow(label: "File Size", value: "\(data.count) bytes")
                        }
                    }
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
    }
}

struct ActionsTabView: View {
    let item: ClipboardItem
    let manager: ClipboardManager
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ActionButton(
                title: item.isPinned ? "Unpin Item" : "Pin Item",
                systemImage: item.isPinned ? "pin.slash.fill" : "pin.fill",
                color: item.isPinned ? DesignSystem.Colors.warning : DesignSystem.Colors.primary
            ) {
                manager.togglePin(for: item)
            }
            
            ActionButton(
                title: "Delete Item",
                systemImage: "trash.fill",
                color: DesignSystem.Colors.error,
                role: .destructive
            ) {
                // manager.deleteItem(item)
            }
            
            Spacer()
        }
        .padding(DesignSystem.Spacing.lg)
    }
}

struct ActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    var role: ButtonRole? = nil
    let action: () -> Void
    
    var body: some View {
        Button(role: role, action: action) {
            Label(title, systemImage: systemImage)
                .font(DesignSystem.Typography.bodyBold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(color)
        .controlSize(.large)
    }
}

struct MetadataSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(DesignSystem.Typography.caption2)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
                .padding(.leading, DesignSystem.Spacing.xs)
            content
                .padding(DesignSystem.Spacing.md)
                .background(DesignSystem.Colors.background, in: RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
        }
    }
}

struct MetadataRow: View {
    let label: String
    let value: String
    
    init(label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    init(label: String, value: Date, format: Date.FormatStyle.DateStyle) {
        self.label = label
        self.value = value.formatted(date: format, time: .omitted)
    }
    
    init(label: String, value: Date, format: Date.FormatStyle.TimeStyle) {
        self.label = label
        self.value = value.formatted(date: .omitted, time: format)
    }

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(DesignSystem.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(DesignSystem.Typography.mono.weight(.medium))
                .foregroundStyle(DesignSystem.Colors.textPrimary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled) // Make metadata values selectable
        }
        .font(DesignSystem.Typography.subheadline)
    }
}
