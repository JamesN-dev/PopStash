import SwiftUI
import AppKit

struct ClipboardMonitorView: View {
    @EnvironmentObject var clipboardManager: ClipboardManager
    @Environment(\.openWindow) private var openWindow
    @State private var lastChangeCount: Int = NSPasteboard.general.changeCount
    
    var body: some View {
        EmptyView()
            .onAppear {
                print("🔍 ClipboardMonitorView appeared - starting monitoring")
                startMonitoring()
            }
    }
    
    private func startMonitoring() {
        print("🔍 Starting clipboard monitoring timer")
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            checkForClipboardChanges()
        }
    }
    
    private func checkForClipboardChanges() {
        let pasteboard = NSPasteboard.general
        
        if pasteboard.changeCount != lastChangeCount {
            print("🔍 Clipboard changed! Count: \(pasteboard.changeCount)")
            lastChangeCount = pasteboard.changeCount
            let frontmostApp = NSWorkspace.shared.frontmostApplication
            
            // Check for image data first
            if let imageData = pasteboard.data(forType: .tiff) {
                print("🔍 Found image data")
                let newItem = ClipboardItem(
                    content: .image(imageData),
                    sourceAppName: frontmostApp?.localizedName,
                    sourceAppBundleID: frontmostApp?.bundleIdentifier
                )
                clipboardManager.history.insert(newItem, at: 0)
                
            // Check for text
            } else if let newText = pasteboard.string(forType: .string) {
                print("🔍 Found text: \(newText.prefix(50))...")
                if !newText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    print("🔍 Showing popup and opening window")
                    
                    // Show the notification popup
                    clipboardManager.popupManager.showPopup(
                        with: newText,
                        onConfirm: { editedText in
                            clipboardManager.finalizeEditedString(editedText)
                        },
                        onCancel: {
                            clipboardManager.finalizeEditedString(newText)
                        }
                    )
                    
                    // Open the notification window
                    print("🔍 Calling openWindow...")
                    openWindow(id: "notification-popup")
                    print("🔍 openWindow called!")
                }
            } else {
                print("🔍 No text or image found")
            }
        }
    }
}