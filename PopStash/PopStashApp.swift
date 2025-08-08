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
    @State private var clipboardManager = ClipboardManager()
    @State private var navigationPath = NavigationPath()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var preferencesManager = PreferencesManager()
    @State private var windowManager = WindowManager()
    @State private var showMetadata = false
    @State private var sidebarAllocated = false // decouple window width from sidebar visibility to avoid flash on close
    @State private var contentMounted = false   // drive initial open transition of content

    // Compute dynamic width: if we're showing root history view use sidebar state, otherwise (preferences) force compact width
    private var mainWindowWidth: CGFloat {
        navigationPath.isEmpty ? (sidebarAllocated ? 600 : 320) : 320
    }

    var body: some Scene {
        // MenuBarExtra with NavigationStack - (clipboard and preferences)
        MenuBarExtra {
            // Show only one root view at a time so sizing recalculates correctly
            Group {
                if contentMounted {
                    Group {
                        if navigationPath.isEmpty {
                            ClipboardHistoryView(
                                showMetadata: $showMetadata,
                                closePopover: {},
                                openPreferences: {
                                    withAnimation(DesignSystem.Animation.smooth) {
                                        showMetadata = false
                                        navigationPath.append("preferences")
                                    }
                                }
                            )
                            .environment(clipboardManager)
                            .environment(preferencesManager)
                            .transition(preferencesManager.reduceAnimations ? .identity : DesignSystem.Transitions.topScale(0.96))
                        } else {
                            PreferencesView(onBack: {
                                if preferencesManager.reduceAnimations {
                                    navigationPath.removeLast()
                                } else {
                                    withAnimation(DesignSystem.Animation.smooth) { navigationPath.removeLast() }
                                }
                            })
                                .environment(preferencesManager)
                                .environment(clipboardManager)
                                .transition(preferencesManager.reduceAnimations ? .identity : DesignSystem.Transitions.topScale(0.96))
                        }
                    }
                }
            }
            .animation(preferencesManager.reduceAnimations ? .none : DesignSystem.Animation.smooth, value: navigationPath) // Smooth size & view swap
            .animation(preferencesManager.reduceAnimations ? .none : DesignSystem.Animation.smooth, value: showMetadata)
            .animation(preferencesManager.reduceAnimations ? .none : DesignSystem.Animation.smooth, value: sidebarAllocated)
            .glassEffect() // Single consistent background & clipping
            .tint(preferencesManager.currentAccentColor)
            .onAppear {
                // Setup clipboard manager synchronously when the view appears
                clipboardManager.popupManager.setWindowManager(windowManager)
                clipboardManager.setPreferencesManager(preferencesManager)
                logger.info("Clipboard manager setup complete")
                // Pre-allocate sidebar width if metadata is always shown to avoid width jump on first open
                if preferencesManager.alwaysShowMetadata {
                    sidebarAllocated = true
                    showMetadata = true
                }
                // Drive initial content transition immediately (no delay); use faster curve for snappier feel
                if preferencesManager.reduceAnimations {
                    contentMounted = true
                } else {
                    withAnimation(DesignSystem.Animation.fast) { contentMounted = true }
                }
            }
            // Dynamic window size based on metadata panel state OR preferences navigation
            .frame(width: mainWindowWidth, height: 550)
            .onDisappear { // Reset state when panel closes so next open shows clipboard history
                navigationPath = NavigationPath()
                showMetadata = false
                sidebarAllocated = false
                contentMounted = false
            }
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
        .onChange(of: showMetadata) { old, new in
            // Expand immediately on open; collapse after sidebar transition completes to avoid list flash
            if preferencesManager.reduceAnimations {
                sidebarAllocated = new
            } else {
                if new {
                    withAnimation(DesignSystem.Animation.smooth) { sidebarAllocated = true }
                } else {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                        withAnimation(DesignSystem.Animation.smooth) { sidebarAllocated = false }
                    }
                }
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
        .restorationBehavior(.disabled)
        .defaultWindowPlacement { windowProxy, context in
            let displayBounds = context.defaultDisplay.visibleRect
            let size = windowProxy.sizeThatFits(.unspecified)
            let position = CGPoint(
                x: displayBounds.maxX - size.width - 20,
                y: displayBounds.minY + 60
            )
            logger.debug("SwiftUI positioning notification at: \(position)")
            return WindowPlacement(position, size: size)
        }

        Window("PopEditor", id: "textEditor") {
            EditorWindowContent(popupManager: clipboardManager.popupManager)
        }
        .windowToolbarStyle(.unified(showsTitle: true))


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
