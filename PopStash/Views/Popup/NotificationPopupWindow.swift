//
//  NotificationPopupManager.swift
//  PopStash
//
//  Created by atetraxx on 7/31/25.
//

import SwiftUI
import AppKit

extension Notification.Name {
    static let showNotificationPopup = Notification.Name("showNotificationPopup")
    static let closeNotificationPopup = Notification.Name("closeNotificationPopup")
}

@Observable
final class NotificationPopupManager {
    var isShowing = false
    var isExpanded = false
    var currentText = ""
    
    private var onConfirm: ((String) -> Void)?
    private var onCancel: (() -> Void)?
    private var autoDismissTimer: Timer?
    
    func showPopup(with text: String, onConfirm: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        // FIXED: Reset state before showing new popup
        stopAutoDismissTimer()
        isExpanded = false
        
        self.currentText = text
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        
        print("🔔 Showing popup with text: \(text.prefix(50))...")

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isShowing = true
        }
        
        // Post notification to show the window
        NotificationCenter.default.post(name: .showNotificationPopup, object: nil)
        
        startAutoDismissTimer()
    }
    
    func expandEditor() {
        stopAutoDismissTimer()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
            isExpanded = true
        }
    }
    
    func confirmEdit(_ editedText: String) {
        onConfirm?(editedText)
        dismissPopup()
    }
    
    func cancelEdit() {
        onCancel?()
        dismissPopup()
    }
    
    func dismissPopup() {
        print("📌 Dismissing popup")
        stopAutoDismissTimer()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isShowing = false
            isExpanded = false
        }
        
        // FIXED: Immediately post close notification, no delay needed
        print("📌 Posting close notification")
        NotificationCenter.default.post(name: .closeNotificationPopup, object: nil)
    }
    
    private func startAutoDismissTimer() {
        print("⏰ Starting auto-dismiss timer")
        stopAutoDismissTimer() // Make sure to stop any existing timer
        autoDismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            print("⏰ Timer fired - isExpanded: \(self?.isExpanded ?? false)")
            if !(self?.isExpanded ?? false) {
                print("📌 Auto-dismissing popup")
                self?.dismissPopup()
            } else {
                print("📌 Not dismissing because popup is expanded")
            }
        }
    }
    
    private func stopAutoDismissTimer() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
    }
}

class NotificationPopupWindow: NSWindow {
    private var popupManager: NotificationPopupManager
    
    init(popupManager: NotificationPopupManager) {
        self.popupManager = popupManager
        
        // Create window with proper settings for popup
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 120),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties - FIXED to allow key window
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.hasShadow = true
        self.ignoresMouseEvents = false
        self.canHide = false
        self.isReleasedWhenClosed = false
        
        // Set up the SwiftUI content
        let contentView = NSHostingView(rootView: NotificationPopupView(popupManager: popupManager))
        self.contentView = contentView
        
        // Listen for notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showPopup),
            name: .showNotificationPopup,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(hidePopup),
            name: .closeNotificationPopup,
            object: nil
        )
    }
    
    // FIXED: Allow window to become key so it can receive input
    override var canBecomeKey: Bool {
        return true
    }
    
    override var canBecomeMain: Bool {
        return true
    }
    
    @objc private func showPopup() {
        // Position window in top-right corner of screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowSize = self.frame.size
            let x = screenFrame.maxX - windowSize.width - 20
            let y = screenFrame.maxY - windowSize.height - 20
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        // Show the window and make it key for input
        self.makeKeyAndOrderFront(nil)
        print("🪟 Popup window displayed on screen")
    }
    
    @objc private func hidePopup() {
        self.orderOut(nil)
        print("🪟 Popup window hidden")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
