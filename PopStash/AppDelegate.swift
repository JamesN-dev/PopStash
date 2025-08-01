// AppDelegate.swift
import SwiftUI
import Carbon

// The AppDelegate is the perfect place to manage app-wide services.
class AppDelegate: NSObject, NSApplicationDelegate {

    // These are now implicitly unwrapped optionals.
    // They will be nil for a moment but are guaranteed to be set up in
    // applicationDidFinishLaunching before any other part of the app needs them.
    private(set) var clipboardManager: ClipboardManager!
    private var hotkey: CarbonHotkey!
    private var popupWindow: NotificationPopupWindow!

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("🚀 App finished launching. Setting up services...")
        
        // 1. Create the ClipboardManager.
        self.clipboardManager = ClipboardManager()

        // 2. Create the popup window that will actually display notifications
        self.popupWindow = NotificationPopupWindow(popupManager: clipboardManager.popupManager)

        // 3. Create the CarbonHotkey.
        //    This now happens in a method where 'self' is fully available,
        //    which solves all the previous compiler errors and crashes.
        self.hotkey = CarbonHotkey(
            keyCode: 8,  // 'C' key
            modifiers: UInt32(optionKey)
        ) { [weak self] in
            // This ensures the hotkey call doesn't crash if the manager is gone.
            self?.clipboardManager.handleClipboardCapture()
        }
        
        print("✅ PopStash is ready.")
    }
}
