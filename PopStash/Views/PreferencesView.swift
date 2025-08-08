import SwiftUI

struct PreferencesView: View {
    @Environment(PreferencesManager.self) private var preferences
    @Environment(ClipboardManager.self) private var clipboardManager
    var onBack: () -> Void = {} // Back action injected by caller

    private let panelWidth: CGFloat = 320 // Target width

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: DesignSystem.Spacing.sm) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DesignSystem.Colors.textSecondary)
                        .frame(width: 28, height: 28) // widen hitbox
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                Text("Preferences")
                    .font(DesignSystem.Typography.bodyBold)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Materials.ultraThin)
            .overlay(Rectangle().fill(DesignSystem.Colors.border).frame(height: 0.5), alignment: .bottom)

            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xl) {

                    PreferencesSection(title: "Hotkeys") {
                        SettingRow(label: "Enable global hotkeys") {
                            Toggle("", isOn: Binding(
                                get: { preferences.enableHotkeys },
                                set: { preferences.enableHotkeys = $0; preferences.savePreferences() }
                            ))
                        }
                        SettingRow(label: "Use Option+C for clipboard capture") {
                            Toggle("", isOn: Binding(
                                get: { preferences.useOptionCHotkey },
                                set: { preferences.useOptionCHotkey = $0; preferences.savePreferences() }
                            ))
                        }
                        .disabled(!preferences.enableHotkeys)
                    }

                    PreferencesSection(title: "Popup Behavior") {
                        SettingRow(label: "Auto-show popup on capture") {
                            Toggle("", isOn: Binding(
                                get: { preferences.autoShowPopup },
                                set: { preferences.autoShowPopup = $0; preferences.savePreferences() }
                            ))
                        }
                        SettingRow(label: "Auto-dismiss after") {
                            Text("\(Int(preferences.popupDismissTime))s")
                                .font(DesignSystem.Typography.mono)
                            Slider(value: Binding(
                                get: { preferences.popupDismissTime },
                                set: { preferences.popupDismissTime = $0; preferences.savePreferences() }
                            ), in: 3...15, step: 1)
                                .frame(width: 100)
                        }
                        .disabled(!preferences.autoShowPopup)
                    }

                    PreferencesSection(title: "History Management") {
                        // Put Maximum history first and keep controls compact
                        SettingRow(label: "Maximum history") {
                            Picker("", selection: Binding(
                                get: { preferences.maxHistoryItems },
                                set: {
                                    preferences.maxHistoryItems = $0
                                    preferences.savePreferences()
                                    clipboardManager.pruneToMaxHistory()
                                }
                            )) {
                                ForEach(preferences.maxHistoryOptions, id: \.self) { count in
                                    Text("\(count) items").tag(count)
                                }
                            }
                            .pickerStyle(.menu) // dropdown style
                            .frame(width: 220, alignment: .trailing)
                        }
                        SettingRow(label: "Clear history on quit") {
                            Toggle("", isOn: Binding(
                                get: { preferences.clearHistoryOnQuit },
                                set: { preferences.clearHistoryOnQuit = $0; preferences.savePreferences() }
                            ))
                        }
                        SettingRow(label: "On unpin, move item to top") {
                            Toggle("", isOn: Binding(
                                get: { preferences.unpinMovesToTop },
                                set: {
                                    preferences.unpinMovesToTop = $0
                                    preferences.savePreferences()
                                    clipboardManager.applyOrdering()
                                }
                            ))
                        }
                    }

                    PreferencesSection(title: "Interface") {
                        SettingRow(label: "Accent color") {
                            Picker("", selection: Binding(
                                get: { preferences.accentColorName },
                                set: { preferences.accentColorName = $0; preferences.savePreferences() }
                            )) {
                                ForEach(preferences.accentColorOptions, id: \.name) { option in
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 16, height: 16)
                                        .tag(option.name)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        SettingRow(label: "Show item count in menu") {
                            Toggle("", isOn: Binding(
                                get: { preferences.showItemCount },
                                set: { preferences.showItemCount = $0; preferences.savePreferences() }
                            ))
                        }
                        SettingRow(label: "Always show metadata sidebar") {
                            Toggle("", isOn: Binding(
                                get: { preferences.alwaysShowMetadata },
                                set: { preferences.alwaysShowMetadata = $0; preferences.savePreferences() }
                            ))
                        }
                        SettingRow(label: "Reduce animations") {
                            Toggle("", isOn: Binding(
                                get: { preferences.reduceAnimations },
                                set: { preferences.reduceAnimations = $0; preferences.savePreferences() }
                            ))
                        }
                        SettingRow(label: "Paste as plain text by default") {
                            Toggle("", isOn: Binding(
                                get: { preferences.pasteAsPlainTextByDefault },
                                set: { preferences.pasteAsPlainTextByDefault = $0; preferences.savePreferences() }
                            ))
                        }
                    }
                }
                .padding(DesignSystem.Spacing.lg)
                .frame(width: panelWidth, alignment: .leading) // Hard constrain content width
            }
            // Footer
            HStack {
                Button("Reset to Defaults", role: .destructive) {
                    preferences.resetToDefaults()
                }
                .buttonStyle(.link)

                Spacer()

                Text("PopStash v1.0")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(DesignSystem.Colors.textSecondary)
            }
            .padding(DesignSystem.Spacing.md)
            .background(DesignSystem.Materials.ultraThin)
            .overlay(Rectangle().fill(DesignSystem.Colors.border).frame(height: 0.5), alignment: .top)
            .frame(width: panelWidth)
        }
        .frame(width: panelWidth) // Single width definition (no glass here)
    }
}

// MARK: - Preview

struct PreferencesView_Previews: PreviewProvider {
    static var previews: some View {
        PreferencesView()
            .environment(PreferencesManager())
            .frame(width: 320)
    }
}
