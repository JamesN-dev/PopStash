//
//  PreferencesView 2.swift
//  PopStash
//
//  Created by atetraxx on 7/31/25.
//


//
//  PreferencesView.swift
//  PopStash
//
//  Created by Blazing Fast Labs on 7/30/25.
//

import SwiftUI

struct PreferencesView: View {
    @Environment(PreferencesManager.self) private var preferences

    var body: some View {
        VStack(spacing: 0) {
                // Header
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.title)
                        .foregroundStyle(Color.accentColor)
                    Text("PopStash Preferences")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .background(.ultraThickMaterial)

                // Content
                Form {
                    Section("Hotkeys") {
                        Toggle("Enable global hotkeys", isOn: .init(
                            get: { preferences.enableHotkeys },
                            set: { preferences.enableHotkeys = $0; preferences.savePreferences() }
                        ))

                        Toggle("Use Option+C for clipboard capture", isOn: .init(
                            get: { preferences.useOptionCHotkey },
                            set: { preferences.useOptionCHotkey = $0; preferences.savePreferences() }
                        ))
                        .disabled(!preferences.enableHotkeys)

                        Text("Option+C captures clipboard content and shows the popup editor")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

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

                    Section("Interface") {
                        HStack {
                            Text("Menu bar icon:")
                            Spacer()
                            Picker("Icon", selection: .init(
                                get: { preferences.menuBarIcon },
                                set: { preferences.menuBarIcon = $0; preferences.savePreferences() }
                            )) {
                                ForEach(preferences.menuBarIconOptions, id: \ .self) { iconName in
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

                        Toggle("Enable hover effect", isOn: .init(
                            get: { preferences.enableHoverEffect },
                            set: { preferences.enableHoverEffect = $0; preferences.savePreferences() }
                        ))

                        Toggle("Show item count in menu", isOn: .init(
                            get: { preferences.showItemCount },
                            set: { preferences.showItemCount = $0; preferences.savePreferences() }
                        ))

                        Toggle("Enable keyboard shortcuts", isOn: .init(
                            get: { preferences.enableKeyboardShortcuts },
                            set: { preferences.enableKeyboardShortcuts = $0; preferences.savePreferences() }
                        ))
                    }

                    Section("Privacy") {
                        Toggle("Enable analytics", isOn: .init(
                            get: { preferences.enableAnalytics },
                            set: { preferences.enableAnalytics = $0; preferences.savePreferences() }
                        ))

                        Text("PopStash respects your privacy. No data is shared without your consent.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .formStyle(.grouped)

                // Footer
                HStack {
                    Button("Reset to Defaults") {
                        preferences.resetToDefaults()
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Text("PopStash v1.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThickMaterial)
            }
        .frame(width: 400, height: 500)
    }
}

#Preview {
    PreferencesView()
        .environment(PreferencesManager())
}
