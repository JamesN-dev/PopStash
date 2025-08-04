//
//  PreferencesView.swift
//  PopStash
//
//  Created by Blazing Fast Labs on 7/30/25.
//

// Preferences view for app settings

import SwiftUI

struct PreferencesView: View {
    @Environment(PreferencesManager.self) private var preferences

    var body: some View {
        Form {
                // Hotkeys section
                Section("Hotkeys") {
                    Toggle("Enable global hotkeys", isOn: Binding(
                        get: { preferences.enableHotkeys },
                        set: { preferences.enableHotkeys = $0; preferences.savePreferences() }
                    ))

                    Toggle("Use Option+C for clipboard capture", isOn: Binding(
                        get: { preferences.useOptionCHotkey },
                        set: { preferences.useOptionCHotkey = $0; preferences.savePreferences() }
                    ))
                    .disabled(!preferences.enableHotkeys)

                    Text("Option+C captures clipboard content and shows the popup editor")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Popup behavior section
                Section("Popup Behavior") {
                    Toggle("Auto-show popup on capture", isOn: .init(
                        get: { preferences.autoShowPopup },
                        set: { preferences.autoShowPopup = $0; preferences.savePreferences() }
                    ))

                    VStack(alignment: .leading) {
                        Text("Auto-dismiss time: \(Int(preferences.popupDismissTime)) seconds")
                        Slider(value: .init(
                            get: { preferences.popupDismissTime },
                            set: { preferences.popupDismissTime = $0; preferences.savePreferences() }
                        ), in: 3...15, step: 1)
                    }
                    .disabled(!preferences.autoShowPopup)

                    Toggle("Enable popup animations", isOn: .init(
                        get: { preferences.enablePopupAnimations },
                        set: { preferences.enablePopupAnimations = $0; preferences.savePreferences() }
                    ))
                }

                // History management section
                Section("History Management") {
                    VStack(alignment: .leading) {
                        Text("Maximum history items: \(preferences.maxHistoryItems)")
                        Picker("Max Items", selection: .init(
                            get: { preferences.maxHistoryItems },
                            set: { preferences.maxHistoryItems = $0; preferences.savePreferences() }
                        )) {
                            ForEach(preferences.maxHistoryOptions, id: \.self) { count in
                                Text("\(count) items").tag(count)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    Toggle("Auto-save to history", isOn: .init(
                        get: { preferences.autoSaveToHistory },
                        set: { preferences.autoSaveToHistory = $0; preferences.savePreferences() }
                    ))

                    Toggle("Clear history on quit", isOn: .init(
                        get: { preferences.clearHistoryOnQuit },
                        set: { preferences.clearHistoryOnQuit = $0; preferences.savePreferences() }
                    ))
                }

                // Interface section
                Section("Interface") {
                    VStack(alignment: .leading) {
                        Text("Window mode:")
                        Picker("Window Mode", selection: .init(
                            get: { preferences.windowMode },
                            set: { preferences.windowMode = $0; preferences.savePreferences() }
                        )) {
                            ForEach(preferences.windowModeOptions, id: \.self) { mode in
                                Text(String(describing: mode).capitalized).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    HStack {
                        Text("Menu bar icon:")
                        Spacer()
                        Picker("Icon", selection: .init(
                            get: { preferences.menuBarIcon },
                            set: { preferences.menuBarIcon = $0; preferences.savePreferences() }
                        )) {
                            ForEach(preferences.menuBarIconOptions, id: \.self) { iconName in
                                Label {
                                    Text(iconName)
                                } icon: {
                                    Image(systemName: iconName)
                                }
                                .tag(iconName)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    HStack {
                        Text("Accent color:")
                        Spacer()
                        Picker("Color", selection: .init(
                            get: { preferences.accentColorName },
                            set: { preferences.accentColorName = $0; preferences.savePreferences() }
                        )) {
                            ForEach(preferences.accentColorOptions, id: \.name) { option in
                                Label {
                                    Text(option.name.capitalized)
                                } icon: {
                                    Circle()
                                        .fill(option.color)
                                        .frame(width: 12, height: 12)
                                }
                                .tag(option.name)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Toggle("Show item count in menu", isOn: .init(
                        get: { preferences.showItemCount },
                        set: { preferences.showItemCount = $0; preferences.savePreferences() }
                    ))

                    Toggle("Enable keyboard shortcuts", isOn: .init(
                        get: { preferences.enableKeyboardShortcuts },
                        set: { preferences.enableKeyboardShortcuts = $0; preferences.savePreferences() }
                    ))
                }

                // Privacy section
                Section {
                    HStack {
                        Button("Reset to Defaults") {
                            preferences.resetToDefaults()
                        }
                        Spacer()
                        Text("PopStash v1.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Preferences")
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Spacer()
                        .frame(width: 16)
                }
            }
            .toolbarBackground(.regularMaterial, for: .windowToolbar)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

#Preview {
    PreferencesView()
        .environment(PreferencesManager())
}
