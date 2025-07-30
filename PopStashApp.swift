//
//  PopStashApp2.swift
//  PopStash
//
//  Created by Blazing Fast Labs on 7/29/25.
//
import SwiftUI

@main
struct PopStashApp: App {
    @StateObject private var clipboardManager = ClipboardManager()

    var body: some Scene {
        // Hidden window that runs clipboard monitoring
        WindowGroup("Background Monitor") {
            ClipboardMonitorView()
                .environmentObject(clipboardManager)
                .frame(width: 1, height: 1)
                .background(Color.clear)
        }
        .windowStyle(.plain)
        .windowResizability(.contentSize)
        .defaultSize(width: 1, height: 1)
        .defaultPosition(.topLeading)
        .windowLevel(.floating)
        
        // This is our menu bar icon and its main popover view.
        MenuBarExtra {
            ClipboardHistoryView()
                .environmentObject(clipboardManager)
        } label: {
            Image(systemName: "doc.on.clipboard")
        }

        // Settings scene 
        Settings {
            VStack {
                Text("PopStash Preferences")
                    .font(.title2)
                    .padding()
                
                Text("Preferences coming soon...")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .frame(width: 400, height: 300)
        }
        

        
        // Notification popup as borderless Window
        Window("Notification Popup", id: "notification-popup") {
            NotificationPopupView(popupManager: clipboardManager.popupManager)
                .background(Color.clear)
                .windowFullScreenBehavior(.disabled)
        }
        .windowStyle(.plain)
        .windowLevel(.floating)
        .windowResizability(.contentSize)
        .windowBackgroundDragBehavior(.disabled)
        .defaultPosition(.topTrailing)
    }
}
