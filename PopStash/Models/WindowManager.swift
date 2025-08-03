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
        
        // Small delay to ensure the window is properly closed before opening
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.openWindow?("notification")
            
            // Position and show the window after it's created
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.positionAndShowNotificationWindow()
            }
        }
    }
    
    private func positionAndShowNotificationWindow() {
        // Find the notification window
        for window in NSApp.windows {
            if window.title == "Notification" {
                logger.debug("Found notification window, positioning and showing")
                
                // Get the main screen bounds
                guard let screen = NSScreen.main else { 
                    logger.error("Could not get main screen")
                    return 
                }
                let screenFrame = screen.visibleFrame
                
                // Set a reasonable size first
                let windowSize = NSSize(width: 360, height: 80)
                
                // Calculate top-right position (AppKit coordinates: bottom-left origin)
                let targetOrigin = NSPoint(
                    x: screenFrame.maxX - windowSize.width - 20,
                    y: screenFrame.maxY - windowSize.height - 60  // Account for menu bar
                )
                
                // Set size and position
                window.setFrame(NSRect(origin: targetOrigin, size: windowSize), display: true)
                
                // Ensure window is visible and on top
                window.makeKeyAndOrderFront(nil)
                window.level = .floating
                window.orderFrontRegardless()
                
                logger.debug("Positioned notification window at: \(targetOrigin), size: \(windowSize)")
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