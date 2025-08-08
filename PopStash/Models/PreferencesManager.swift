//
//  PreferencesManager.swift
//  PopStash
//
//  Created by Blazing Fast Labs on 7/30/25.
//

import Foundation
import SwiftUI

/// Modern SwiftUI preferences manager using @Observable pattern
/// Handles all app settings and user preferences
@Observable
final class PreferencesManager {
    // MARK: - Window Mode Preference
    enum WindowMode: String, Codable, CaseIterable {
        case compact
        case expanded
        case resizable
    }

    var windowMode: WindowMode = .compact

    // MARK: - Hotkey Preferences
    var useOptionCHotkey: Bool = true
    var enableHotkeys: Bool = true

    // MARK: - Popup Preferences
    var autoShowPopup: Bool = true
    var popupDismissTime: Double = 5.0
    var enablePopupAnimations: Bool = true

    // MARK: - History Preferences
    var maxHistoryItems: Int = 100
    var autoSaveToHistory: Bool = true
    var enableImageCapture: Bool = false  // MVP is text-only
    var unpinMovesToTop: Bool = false // NEW: controls unpin behavior

    // MARK: - UI Preferences
    var menuBarIcon: String = "doc.on.clipboard"
    var accentColorName: String = "blue"
    var showItemCount: Bool = true
    var enableKeyboardShortcuts: Bool = true
    var enableHoverEffect: Bool = true
    // Global UI animation toggle
    var reduceAnimations: Bool = false
    var lastClipboardWindowPosition: CGPoint? = nil
    // Sidebar visibility preference
    var alwaysShowMetadata: Bool = false
    // Paste mode preference: when true, favor plain text when copying back
    var pasteAsPlainTextByDefault: Bool = false
    // UI hint preference: show or hide the “⌥+click to edit” hover hint
    var showOptionClickHint: Bool = true

    // MARK: - Privacy Preferences
    var clearHistoryOnQuit: Bool = false
    var enableAnalytics: Bool = false  // No implementation yet. Placeholder.

    // MARK: - Storage
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "PopStashPreferences"

    init() {
        loadPreferences()
        print("🔧 PreferencesManager init - enableHotkeys: \(enableHotkeys), enableKeyboardShortcuts: \(enableKeyboardShortcuts)")
    }

    // MARK: - Persistence
    func savePreferences() {
        let preferences = PreferencesData(
            useOptionCHotkey: useOptionCHotkey,
            enableHotkeys: enableHotkeys,
            autoShowPopup: autoShowPopup,
            popupDismissTime: popupDismissTime,
            enablePopupAnimations: enablePopupAnimations,
            maxHistoryItems: maxHistoryItems,
            autoSaveToHistory: autoSaveToHistory,
            enableImageCapture: enableImageCapture,
            menuBarIcon: menuBarIcon,
            accentColorName: accentColorName,
            showItemCount: showItemCount,
            enableKeyboardShortcuts: enableKeyboardShortcuts,
            clearHistoryOnQuit: clearHistoryOnQuit,
            enableAnalytics: enableAnalytics,
            enableHoverEffect: enableHoverEffect,
            reduceAnimations: reduceAnimations,
            windowMode: windowMode,
            unpinMovesToTop: unpinMovesToTop,
            alwaysShowMetadata: alwaysShowMetadata,
            pasteAsPlainTextByDefault: pasteAsPlainTextByDefault,
            showOptionClickHint: showOptionClickHint
        )

        if let encoded = try? JSONEncoder().encode(preferences) {
            userDefaults.set(encoded, forKey: preferencesKey)
        }
    }

    private func loadPreferences() {
        guard let data = userDefaults.data(forKey: preferencesKey),
            let preferences = try? JSONDecoder().decode(PreferencesData.self, from: data)
        else { return }

        useOptionCHotkey = preferences.useOptionCHotkey
        enableHotkeys = preferences.enableHotkeys
        autoShowPopup = preferences.autoShowPopup
        popupDismissTime = preferences.popupDismissTime
        enablePopupAnimations = preferences.enablePopupAnimations
        maxHistoryItems = preferences.maxHistoryItems
        autoSaveToHistory = preferences.autoSaveToHistory
        enableImageCapture = preferences.enableImageCapture
        menuBarIcon = preferences.menuBarIcon
        accentColorName = preferences.accentColorName ?? "blue"
        showItemCount = preferences.showItemCount
        enableKeyboardShortcuts = preferences.enableKeyboardShortcuts
        clearHistoryOnQuit = preferences.clearHistoryOnQuit
        enableAnalytics = preferences.enableAnalytics
        enableHoverEffect = preferences.enableHoverEffect
    reduceAnimations = preferences.reduceAnimations ?? false
        windowMode = preferences.windowMode
        unpinMovesToTop = preferences.unpinMovesToTop
    alwaysShowMetadata = preferences.alwaysShowMetadata ?? false
    pasteAsPlainTextByDefault = preferences.pasteAsPlainTextByDefault ?? false
    showOptionClickHint = preferences.showOptionClickHint ?? true
    }

    // MARK: - Actions
    func resetToDefaults() {
        useOptionCHotkey = true
        enableHotkeys = true
        autoShowPopup = true
        popupDismissTime = 5.0
        enablePopupAnimations = true
        maxHistoryItems = 100
        autoSaveToHistory = true
        enableImageCapture = false
        menuBarIcon = "doc.on.clipboard"
        accentColorName = "blue"
        showItemCount = true
        enableKeyboardShortcuts = true
        clearHistoryOnQuit = false
        enableAnalytics = false
        enableHoverEffect = true
    reduceAnimations = false
        unpinMovesToTop = false
    alwaysShowMetadata = false
    pasteAsPlainTextByDefault = false
    showOptionClickHint = true

        savePreferences()
    }
}

// MARK: - Preferences Data Model
private struct PreferencesData: Codable {
    let useOptionCHotkey: Bool
    let enableHotkeys: Bool
    let autoShowPopup: Bool
    let popupDismissTime: Double
    let enablePopupAnimations: Bool
    let maxHistoryItems: Int
    let autoSaveToHistory: Bool
    let enableImageCapture: Bool
    let menuBarIcon: String
    let accentColorName: String?
    let showItemCount: Bool
    let enableKeyboardShortcuts: Bool
    let clearHistoryOnQuit: Bool
    let enableAnalytics: Bool
    let enableHoverEffect: Bool
    let reduceAnimations: Bool?
    let windowMode: PreferencesManager.WindowMode
    let unpinMovesToTop: Bool // NEW
    let alwaysShowMetadata: Bool? // NEW optional for backward compatibility
    let pasteAsPlainTextByDefault: Bool? // NEW optional for backward compatibility
    let showOptionClickHint: Bool? // NEW optional for backward compatibility
}

// MARK: - Convenience Extensions
extension PreferencesManager {
    var windowModeOptions: [WindowMode] {
        WindowMode.allCases
    }
    var popupDismissTimeOptions: [Double] {
        [3.0, 5.0, 7.0, 10.0, 15.0]
    }

    var maxHistoryOptions: [Int] {
        [50, 100, 200, 500, 1000]
    }

    var menuBarIconOptions: [String] {
        ["doc.on.clipboard", "clipboard", "doc.text", "square.and.pencil"]
    }

    var accentColorOptions: [(name: String, color: Color)] {
        [
            ("blue", .blue),
            ("purple", .purple),
            ("pink", .pink),
            ("red", .red),
            ("orange", .orange),
            ("yellow", .yellow),
            ("green", .green),
            ("mint", .mint),
            ("teal", .teal),
            ("cyan", .cyan),
            ("indigo", .indigo)
        ]
    }

    var currentAccentColor: Color {
        accentColorOptions.first { $0.name == accentColorName }?.color ?? .blue
    }
}
