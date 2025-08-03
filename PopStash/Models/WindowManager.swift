//
//  WindowManager.swift
//  PopStash
//
//  Manages window lifecycle for PopStash windows
//

import SwiftUI
import Observation
import OSLog
import AppKit

private let logger = Logger(subsystem: "com.popstash.app", category: "window-manager")

@Observable
final class WindowManager {
    private var openWindow: ((String) -> Void)?
    private var dismissWindow: ((String) -> Void)?
    
    func setWindowActions(openWindow: @escaping (String) -> Void, dismissWindow: @escaping (String) -> Void) {
        self.openWindow = openWindow
        self.dismissWindow = dismissWindow
    }
    
    func openNotificationWindow() {
        logger.debug("Opening notification window")
        
        // Force close any existing notification window first
        dismissWindow?("notification")
        
        // Small delay to ensure the window is properly closed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.openWindow?("notification")
            
            // Force position the window after opening
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.forcePositionNotificationWindow()
            }
        }
    }
    
    private func forcePositionNotificationWindow() {
        // Find the notification window and force its position
        for window in NSApp.windows {
            if window.title == "Notification" || window.identifier?.rawValue == "notification" {
                logger.debug("Found notification window, forcing position to top-right")
                
                // Get the main screen bounds
                guard let screen = NSScreen.main else { return }
                let screenFrame = screen.visibleFrame
                let windowSize = window.frame.size
                
                // Calculate top-right position
                let targetOrigin = NSPoint(
                    x: screenFrame.maxX - windowSize.width - 20,
                    y: screenFrame.maxY - windowSize.height - 20
                )
                
                // Force set the window position
                window.setFrameOrigin(targetOrigin)
                logger.debug("Forced notification window to position: \(targetOrigin)")
                break
            }
        }
    }
    
    func closeNotificationWindow() {
        logger.debug("Closing notification window")
        dismissWindow?("notification")
    }
    
    func openEditorWindow() {
        logger.debug("Opening editor window")
        openWindow?("textEditor")
    }
    
    func closeEditorWindow() {
        logger.debug("Closing editor window")
        dismissWindow?("textEditor")
    }
}