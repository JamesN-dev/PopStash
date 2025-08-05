import SwiftUI

struct PreferencesView: View {
    @Environment(PreferencesManager.self) private var preferences

    var body: some View {
        VStack(spacing: 0) {
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
                        SettingRow(label: "Maximum history") {
                            Picker("", selection: Binding(
                                get: { preferences.maxHistoryItems },
                                set: { preferences.maxHistoryItems = $0; preferences.savePreferences() }
                            )) {
                                ForEach(preferences.maxHistoryOptions, id: \.self) { count in
                                    Text("\(count) items").tag(count)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        SettingRow(label: "Clear history on quit") {
                            Toggle("", isOn: Binding(
                                get: { preferences.clearHistoryOnQuit },
                                set: { preferences.clearHistoryOnQuit = $0; preferences.savePreferences() }
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
                    }
                }
                .padding(DesignSystem.Spacing.lg)
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
        }
        .glassEffect()
        // FIX: Apply the correct frame width to match the main panel.
        .frame(width: 320)
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
