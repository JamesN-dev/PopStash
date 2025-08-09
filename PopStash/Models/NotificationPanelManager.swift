//
//  NotificationPanelManager.swift
//  PopStash
//
//  Manages a reusable NSPanel for notification popups to avoid memory leaks
//

import SwiftUI
import AppKit
import OSLog

private let logger = Logger(subsystem: "com.popstash.popup", category: "panel")

@Observable
final class NotificationPanelManager {
    private var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?
    private var windowManager: WindowManager?
    private var preferencesManager: PreferencesManager?
    
    var isShowing = false
    var currentText = ""
    private var onConfirmCallback: ((String) -> Void)?
    private var onCancelCallback: (() -> Void)?
    private var autoDismissTimer: Timer?
    
    init() {
        setupPanel()
    }
    
    func setWindowManager(_ windowManager: WindowManager) {
        self.windowManager = windowManager
    }
    
    func setPreferencesManager(_ preferencesManager: PreferencesManager) {
        self.preferencesManager = preferencesManager
    }
    
    private func setupPanel() {
        // Create the panel with non-activating style
        panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 340, height: 72),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        guard let panel = panel else { return }
        
        // Configure panel properties
        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
        panel.collectionBehavior = [.canJoinAllSpaces, .transient]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false // We'll handle shadows in SwiftUI
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        
        // Position panel in top-right corner
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let panelFrame = panel.frame
            let x = screenFrame.maxX - panelFrame.width - 20
            let y = screenFrame.maxY - panelFrame.height - 20  // Changed from minY to maxY
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        logger.debug("Popup panel created and configured")
    }
    
    func showPopup(with text: String, onConfirm: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        guard let panel = panel, let preferencesManager = preferencesManager else {
            logger.error("Panel or PreferencesManager not available")
            return
        }
        
        // Stop any existing timer
        stopAutoDismissTimer()
        
        // Update state
        self.currentText = text
        self.onConfirmCallback = onConfirm
        self.onCancelCallback = onCancel
        
        // Create the SwiftUI view with environment objects
        let notificationView = NotificationPopupView(
            popupManager: self,
            isDragging: false
        )
        .environment(preferencesManager) // Correct syntax for @Observable types!
        
        // Wrap in AnyView for type erasure
        let wrappedView = AnyView(notificationView)
        
        if hostingView == nil {
            hostingView = NSHostingView(rootView: wrappedView)
            panel.contentView = hostingView
        } else {
            hostingView?.rootView = wrappedView
        }
        
        // Show the panel
        panel.orderFrontRegardless()
        isShowing = true
        
        // Start auto-dismiss timer
        startAutoDismissTimer()
        
        logger.info("Popup panel shown with text: \(text.prefix(50))")
    }
    
    func dismissPopup() {
        guard let panel = panel else { return }
        
        stopAutoDismissTimer()
        panel.orderOut(nil)
        isShowing = false
        
        logger.debug("Popup panel dismissed")
    }
    
    func confirmEdit(_ editedText: String) {
        onConfirmCallback?(editedText)
        dismissPopup()
    }
    
    func cancelEdit() {
        onCancelCallback?()
        dismissPopup()
    }
    
    func openEditorWindow() {
        // Open the editor window via WindowManager
        windowManager?.openEditorWindow()
        // Dismiss the notification when opening editor
        dismissPopup()
        logger.debug("Editor window requested from notification panel")
    }
    
    private func startAutoDismissTimer() {
        autoDismissTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
            self?.dismissPopup()
        }
    }
    
    private func stopAutoDismissTimer() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
    }
    
    deinit {
        stopAutoDismissTimer()
        panel?.close()
        logger.debug("NotificationPanelManager deinitialized")
    }
}

// MARK: - Compatibility Protocol
// This allows the new panel manager to work with existing NotificationPopupView
extension NotificationPanelManager {
    // These methods match the old NotificationPopupManager interface
    var text: String { currentText }
}
