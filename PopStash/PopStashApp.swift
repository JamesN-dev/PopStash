// PopStashApp.swift
import SwiftUI

@main
struct PopStashApp: App {
    // This adapter ensures our AppDelegate runs on launch.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            if let clipboardManager = appDelegate.clipboardManager {
                ClipboardHistoryView()
                    .environment(clipboardManager)
            } else {
                Text("Loading...")
                    .padding()
            }
        } label: {
            Image(systemName: "doc.on.clipboard")
        }

        Settings {
            PreferencesView()
                .environment(PreferencesManager())
        }

        // Your WindowGroup for the popup
        WindowGroup(id: "notification-popup") {
            if let clipboardManager = appDelegate.clipboardManager {
                NotificationPopupView(popupManager: clipboardManager.popupManager)
                    .background(Color.clear)
                    .windowFullScreenBehavior(.disabled)
            } else {
                Color.clear
                    .windowFullScreenBehavior(.disabled)
            }
        }
        .windowStyle(.plain)
        .windowLevel(.floating)
        .windowResizability(.contentSize)
        .windowBackgroundDragBehavior(.disabled)
        .defaultPosition(.topTrailing)
    }
}
