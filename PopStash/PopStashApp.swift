// PopStashApp.swift
// Allow direct interpolation of CGSize in Logger statements
extension CGSize: @retroactive CustomStringConvertible {
    public var description: String {
        "(\(width), \(height))"
    }
}
import SwiftUI
import OSLog
// Allow direct interpolation of CGPoint in Logger statements
import CoreGraphics

extension CGPoint: @retroactive CustomStringConvertible {
    public var description: String {
        "(\(x), \(y))"
    }
}

private let logger = Logger(subsystem: "com.popstash.app", category: "main")

@main
struct PopStashApp: App {
    // This adapter ensures our AppDelegate runs on launch.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var clipboardManager = ClipboardManager()
    @State private var navigationPath = NavigationPath()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var preferencesManager = PreferencesManager()
    @State private var windowManager = WindowManager()

    var body: some Scene {
        // MenuBarExtra with NavigationStack - (clipboard and preferences)
        MenuBarExtra {
            NavigationStack(path: $navigationPath) {
                ClipboardHistoryView(
                    closePopover: { /* Custom close logic, respects Pin state */ },
                    openPreferences: {
                        navigationPath.append("preferences")
                    }
                )
                .environment(clipboardManager)
                .environment(preferencesManager)
                .navigationDestination(for: String.self) { destination in
                    if destination == "preferences" {
                        PreferencesView()
                            .environment(preferencesManager)
                    }
                }
            }
            .task {
                appDelegate.setClipboardManager(clipboardManager)
                clipboardManager.popupManager.setWindowManager(windowManager)
                logger.info("Clipboard manager setup complete")
            }
            // Default window size only
            .frame(width: 400, height: 550)
        } label: {
            // Dynamic menu bar label
            HStack(spacing: 4) {
                Image(systemName: preferencesManager.menuBarIcon)
                if preferencesManager.showItemCount && clipboardManager.history.count > 0 {
                    Text("\(clipboardManager.history.count)")
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                }
            }
        }
        .menuBarExtraStyle(.window)
        .defaultWindowPlacement { windowProxy, context in
            let displayBounds = context.defaultDisplay.visibleRect
            let size = windowProxy.sizeThatFits(.unspecified)
            // Position in top-right corner, just below menu bar
            let position = CGPoint(
                x: displayBounds.maxX - size.width - 10,
                y: displayBounds.minY + 25
            )
            return WindowPlacement(position, size: size)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                logger.debug("App became active")
                // Set up window manager when app becomes active
                windowManager.setWindowActions(
                    openWindow: { id in openWindow(id: id) },
                    dismissWindow: { id in dismissWindow(id: id) }
                )
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
                windowManager.openNotificationWindow()
            } else {
                windowManager.closeNotificationWindow()
            }
        }

        // Popup notification window
        Window("Notification", id: "notification") {
            NotificationPopupOverlay(popupManager: clipboardManager.popupManager)
                .environment(preferencesManager)
        }
        .windowStyle(.plain)
        .windowLevel(.floating)
        .windowBackgroundDragBehavior(.disabled)
        .windowResizability(.contentMinSize)
        .restorationBehavior(.disabled)  // Disable saving/restoring this window's state
        .defaultWindowPlacement { windowProxy, context in
            let displayBounds = context.defaultDisplay.visibleRect
            let size = windowProxy.sizeThatFits(.unspecified)
            // Always position at top-right corner, ignore drag state
            let position = CGPoint(
                x: displayBounds.maxX - size.width - 20,
                y: displayBounds.minY + 20
            )
            logger.debug("Notification window placement: \(position), size: \(size)")
            return WindowPlacement(position, size: size)
        }

        Window("PopEditor", id: "textEditor") {
            EditorWindowContent(popupManager: clipboardManager.popupManager)
        }
        .windowResizability(.contentSize)
        .windowLevel(.floating)
        .defaultWindowPlacement { windowProxy, context in
            let displayBounds = context.defaultDisplay.visibleRect
            let size = windowProxy.sizeThatFits(.unspecified)
            
            // Position in top-right corner like the notification popup
            let position = CGPoint(
                x: displayBounds.maxX - size.width - 20,
                y: displayBounds.minY + 20
            )

            return WindowPlacement(position, size: size)
        }
    }
}
