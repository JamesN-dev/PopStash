// AppDelegate.swift
import SwiftUI
import Carbon
import OSLog

private let logger = Logger(subsystem: "com.popstash.app", category: "delegate")

// The AppDelegate is the perfect place to manage app-wide services.
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // Keep reference to clipboard manager set by PopStashApp
    private(set) var clipboardManager: ClipboardManager?
    
    func setClipboardManager(_ manager: ClipboardManager) {
        self.clipboardManager = manager
    }

    @MainActor
    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("App finished launching")
        logger.info("PopStash is ready")
    }
}
