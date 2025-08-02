// PopStashApp.swift
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.popstash.app", category: "main")

@main
struct PopStashApp: App {
    // This adapter ensures our AppDelegate runs on launch.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var clipboardManager = ClipboardManager()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some Scene {
        MenuBarExtra("Clipboard History", systemImage: "doc.on.clipboard") {
            ClipboardHistoryView(openPreferences: {
                openWindow(id: "settings")
            })
                .environment(clipboardManager)
                .frame(minWidth: 420, maxWidth: .infinity, minHeight: 500, maxHeight: .infinity)
                .task {
                    appDelegate.setClipboardManager(clipboardManager)
                    logger.info("Clipboard manager setup complete")
                }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                logger.debug("App became active")
            case .inactive:
                logger.debug("App became inactive")
            case .background:
                logger.debug("App went to background")
            @unknown default:
                break
            }
        }
        .onChange(of: clipboardManager.popupManager.isShowing) { oldValue, isShowing in
            if isShowing {
                openWindow(id: "notification")
            } else {
                dismissWindow(id: "notification")
            }
        }
        
        Window("Preferences", id: "settings") {
            PreferencesView()
                .environment(PreferencesManager())
        }
        .windowResizability(.contentSize)
        
        // Popup notification window
        Window("Notification", id: "notification") {
            NotificationPopupOverlay(popupManager: clipboardManager.popupManager)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowLevel(.floating)
        .windowResizability(.contentSize)
        .defaultWindowPlacement { windowProxy, context in
            let displayBounds = context.defaultDisplay.visibleRect
            let size = windowProxy.sizeThatFits(.unspecified)
            
            // Position at top-right corner
            let position = CGPoint(
                x: displayBounds.maxX - size.width - 50,  // More left padding
                y: displayBounds.minY + 80   // More top padding
            )
            
            return WindowPlacement(position, size: size)
        }
        
        Window("Text Editor", id: "textEditor") {
            PopEditor(
                text: "",
                onConfirm: { _ in },
                onCancel: { }
            )
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultWindowPlacement { windowProxy, context in
            let displayBounds = context.defaultDisplay.visibleRect
            let size = windowProxy.sizeThatFits(.unspecified)
            
            // Position in center of screen
            let position = CGPoint(
                x: displayBounds.midX - (size.width / 2),
                y: displayBounds.midY - (size.height / 2)
            )
            
            return WindowPlacement(position, size: size)
        }
        .windowLevel(.floating)
    }
}
