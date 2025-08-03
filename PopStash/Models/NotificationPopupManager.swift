//
//  NotificationPopupManager.swift
//  PopStash
//
//  Created by atetraxx on 8/2/25.
//


import SwiftUI
import Observation
import OSLog

private let logger = Logger(subsystem: "com.popstash.popup", category: "manager")

@Observable
final class NotificationPopupManager {
    var isShowing = false
    var currentText = ""
    
    // Weak reference to parent ClipboardManager to avoid retain cycle
    private weak var clipboardManager: ClipboardManager?
    
    // Reference to window manager for opening editor window
    private var windowManager: WindowManager?
    
    private var onConfirmCallback: ((String) -> Void)?
    private var onCancelCallback: (() -> Void)?
    private var autoDismissTimer: Timer?
    
    // Initialize with reference to parent ClipboardManager
    init(clipboardManager: ClipboardManager? = nil) {
        self.clipboardManager = clipboardManager
    }
    
    // Set the clipboard manager reference after initialization
    func setClipboardManager(_ manager: ClipboardManager) {
        self.clipboardManager = manager
    }
    
    // Set the window manager reference for opening editor window
    func setWindowManager(_ manager: WindowManager) {
        self.windowManager = manager
    }
    
    func openEditorWindow() {
        logger.debug("Opening editor window from notification")
        stopAutoDismissTimer()
        windowManager?.openEditorWindow()
        dismissPopup() // Close the notification popup
    }
    
    func showPopup(with text: String, onConfirm: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        // Reset state before showing new popup
        stopAutoDismissTimer()
        
        self.currentText = text
        self.onConfirmCallback = onConfirm
        self.onCancelCallback = onCancel
        
        logger.info("Showing popup with text: \(text.prefix(50))")

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isShowing = true
        }
        
        startAutoDismissTimer()
    }
    
    func confirmEdit(_ editedText: String) {
        onConfirmCallback?(editedText)
        dismissPopup()
    }
    
    func cancelEdit() {
        onCancelCallback?()
        dismissPopup()
    }
    
    func dismissPopup() {
        logger.debug("Dismissing popup")
        stopAutoDismissTimer()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isShowing = false
        }
    }
    
    func hide() {
        dismissPopup()
    }
    
    private func startAutoDismissTimer() {
        logger.debug("Starting auto-dismiss timer")
        stopAutoDismissTimer() // Make sure to stop any existing timer
        autoDismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            logger.debug("Timer fired - auto-dismissing popup")
            self?.dismissPopup()
        }
    }
    
    private func stopAutoDismissTimer() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
    }
}
