// PopStashApp.swift
import SwiftUI
import OSLog

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
    @Environment(\.dismiss) private var dismiss
    private let preferencesManager = PreferencesManager()

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
        // Popup notification window
        Window("Notification", id: "notification") {
            NotificationPopupOverlay(popupManager: clipboardManager.popupManager)
                .environment(preferencesManager)
        }
        .windowStyle(.plain)
        .windowLevel(.floating)
        .windowBackgroundDragBehavior(.enabled)
        .windowResizability(preferencesManager.windowMode == .resizable ? .contentSize : .contentMinSize)
        .defaultWindowPlacement { windowProxy, context in
            let displayBounds = context.defaultDisplay.visibleRect
            let size = windowProxy.sizeThatFits(.unspecified)
            // Position at top-right corner (macOS coordinates: origin at bottom-left)
            let position = CGPoint(
                x: displayBounds.maxX - size.width - 20,  // Right edge minus width
                y: displayBounds.maxY - size.height - 20   // Top edge minus height (macOS coords)
            )
            return WindowPlacement(position, size: size)
        }

        Window("PopEditor", id: "textEditor") {
            NavigationStack {
                PopEditor(
                    text: "",
                    isDragging: false,
                    onConfirm: { _ in },
                    onCancel: { }
                )
                .navigationTitle("PopEditor")
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Spacer()
                            .frame(width: 16)
                    }
                }
                .toolbarBackground(.regularMaterial, for: .windowToolbar)
            }
        }
        .windowStyle(.automatic)
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
