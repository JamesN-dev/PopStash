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
    var isExpanded = false
    var currentText = ""
    
    // Weak reference to parent ClipboardManager to avoid retain cycle
    private weak var clipboardManager: ClipboardManager?
    
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
    
    func showPopup(with text: String, onConfirm: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        // Reset state before showing new popup
        stopAutoDismissTimer()
        isExpanded = false
        
        self.currentText = text
        self.onConfirmCallback = onConfirm
        self.onCancelCallback = onCancel
        
        logger.info("Showing popup with text: \(text.prefix(50))")

        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isShowing = true
        }
        
        startAutoDismissTimer()
    }
    
    func expandEditor() {
        stopAutoDismissTimer()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
            isExpanded = true
        }
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
            isExpanded = false
        }
    }
    
    func hide() {
        dismissPopup()
    }
    
    private func startAutoDismissTimer() {
        logger.debug("Starting auto-dismiss timer")
        stopAutoDismissTimer() // Make sure to stop any existing timer
        autoDismissTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            logger.debug("Timer fired - isExpanded: \(self?.isExpanded ?? false)")
            if !(self?.isExpanded ?? false) {
                logger.debug("Auto-dismissing popup")
                self?.dismissPopup()
            } else {
                logger.debug("Not dismissing because popup is expanded")
            }
        }
    }
    
    private func stopAutoDismissTimer() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
    }
}
