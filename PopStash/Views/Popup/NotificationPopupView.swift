//
//  NotificationPopupView.swift
//  PopStash
//
//  Created by atetraxx on 7/31/25.
//


// NotificationPopupView.swift
import SwiftUI
import OSLog

private let logger = Logger(subsystem: "com.popstash.popup", category: "view")

struct NotificationPopupView: View {
    @Bindable var popupManager: NotificationPopupManager
    @Environment(\.dismiss) private var dismiss
    let isDragging: Bool // Received from parent overlay

    init(popupManager: NotificationPopupManager, isDragging: Bool) {
        self.popupManager = popupManager
        self.isDragging = isDragging
    }

    var body: some View {
        collapsedNotification
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
            .frame(width: 340, height: 72)
    }

    private var collapsedNotification: some View {
        Button(action: {
            popupManager.openEditorWindow()
        }) {
            HStack(spacing: 14) {
                // Animated clipboard icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Copied")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.primary)
                        Spacer()
                        // Subtle edit hint
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 10, weight: .medium))
                            Text("Click to edit")
                                .font(.system(size: 10, weight: .medium))
                        }
                        .foregroundStyle(.secondary)
                        .opacity(0.8)
                    }
                    Text(truncatedText)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .buttonStyle(PopButtonStyle())
        .allowsWindowActivationEvents()
    }

    private var truncatedText: String {
        let maxLength = 50
        if popupManager.currentText.count > maxLength {
            return String(popupManager.currentText.prefix(maxLength)) + "…"
        }
        return popupManager.currentText
    }
}

// MARK: - NotificationPopupOverlay
// This wrapper ensures the popup appears in a floating context
struct NotificationPopupOverlay: View {
    @Bindable var popupManager: NotificationPopupManager
    @State private var isDragging = false // Track drag state for styling

    var body: some View {
        if popupManager.isShowing {
            NotificationPopupView(popupManager: popupManager, isDragging: isDragging)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                    removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.95))
                ))
                .gesture(
                    // Higher minimum distance to avoid interfering with text editing
                    DragGesture(minimumDistance: 10)
                        .onChanged { _ in
                            isDragging = true
                        }
                        .onEnded { _ in
                            // Small delay before removing blue outline
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                isDragging = false
                            }
                        }
                        .simultaneously(with: WindowDragGesture())
                )
                .onAppear {
                    logger.debug("NotificationPopupOverlay: popup appeared")
                }
        }
    }

}
