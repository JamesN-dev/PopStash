import SwiftUI

extension Notification.Name {
    static let closeNotificationPopup = Notification.Name("closeNotificationPopup")
}

class NotificationPopupManager: ObservableObject {
    @Published var isShowing = false
    @Published var isExpanded = false
    @Published var currentText = ""
    
    private var onConfirm: ((String) -> Void)?
    private var onCancel: (() -> Void)?
    private var autoDismissTimer: Timer?
    
    func showPopup(with text: String, onConfirm: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.currentText = text
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        
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
        onConfirm?(editedText)
        dismissPopup()
    }
    
    func cancelEdit() {
        onCancel?()
        dismissPopup()
    }
    
    func dismissPopup() {
        stopAutoDismissTimer()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            isShowing = false
            isExpanded = false
        }
        
        // Post notification to close the window
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(name: .closeNotificationPopup, object: nil)
        }
    }
    
    private func startAutoDismissTimer() {
        autoDismissTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            if !(self?.isExpanded ?? false) {
                self?.dismissPopup()
            }
        }
    }
    
    private func stopAutoDismissTimer() {
        autoDismissTimer?.invalidate()
        autoDismissTimer = nil
    }
}