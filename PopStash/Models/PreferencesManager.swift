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

    // MARK: - UI Preferences
    var menuBarIcon: String = "doc.on.clipboard"
    var showItemCount: Bool = true
    var enableKeyboardShortcuts: Bool = true
    var enableHoverEffect: Bool = true
    var lastClipboardWindowPosition: CGPoint? = nil

    // MARK: - Privacy Preferences
    var clearHistoryOnQuit: Bool = false
    var enableAnalytics: Bool = false  // No implementation yet. Placeholder.

    // MARK: - Storage
    private let userDefaults = UserDefaults.standard
    private let preferencesKey = "PopStashPreferences"

    init() {
        loadPreferences()
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
            showItemCount: showItemCount,
            enableKeyboardShortcuts: enableKeyboardShortcuts,
            clearHistoryOnQuit: clearHistoryOnQuit,
            enableAnalytics: enableAnalytics,
            enableHoverEffect: enableHoverEffect
        )

        if let encoded = try? JSONEncoder().encode(preferences) {
            userDefaults.set(encoded, forKey: preferencesKey)
        }
    }

    private func loadPreferences() {
        guard let data = userDefaults.data(forKey: preferencesKey),
            let preferences = try? JSONDecoder().decode(PreferencesData.self, from: data)
        else {
            return  // Use defaults
        }

        useOptionCHotkey = preferences.useOptionCHotkey
        enableHotkeys = preferences.enableHotkeys
        autoShowPopup = preferences.autoShowPopup
        popupDismissTime = preferences.popupDismissTime
        enablePopupAnimations = preferences.enablePopupAnimations
        maxHistoryItems = preferences.maxHistoryItems
        autoSaveToHistory = preferences.autoSaveToHistory
        enableImageCapture = preferences.enableImageCapture
        menuBarIcon = preferences.menuBarIcon
        showItemCount = preferences.showItemCount
        enableKeyboardShortcuts = preferences.enableKeyboardShortcuts
        clearHistoryOnQuit = preferences.clearHistoryOnQuit
        enableAnalytics = preferences.enableAnalytics
        enableHoverEffect = preferences.enableHoverEffect
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
        showItemCount = true
        enableKeyboardShortcuts = true
        clearHistoryOnQuit = false
        enableAnalytics = false
        enableHoverEffect = true

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
    let showItemCount: Bool
    let enableKeyboardShortcuts: Bool
    let clearHistoryOnQuit: Bool
    let enableAnalytics: Bool
    let enableHoverEffect: Bool
}

// MARK: - Convenience Extensions
extension PreferencesManager {
    var popupDismissTimeOptions: [Double] {
        [3.0, 5.0, 7.0, 10.0, 15.0]
    }

    var maxHistoryOptions: [Int] {
        [50, 100, 200, 500, 1000]
    }

    var menuBarIconOptions: [String] {
        ["doc.on.clipboard", "clipboard", "doc.text", "square.and.pencil"]
    }
}
