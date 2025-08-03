//
//  NotificationPopupView.swift
//  PopStash
//
//  Created by atetraxx on 7/31/25.
//


// NotificationPopupView.swift
import SwiftUI

struct NotificationPopupView: View {
    @Bindable var popupManager: NotificationPopupManager
    @FocusState private var isTextEditorFocused: Bool
    @Environment(\.dismiss) private var dismiss
    let isDragging: Bool // Received from parent overlay

    // Dynamic window sizing for smooth morphing
    @State private var windowSize: CGSize = CGSize(width: 340, height: 72)

    init(popupManager: NotificationPopupManager, isDragging: Bool) {
        self.popupManager = popupManager
        self.isDragging = isDragging
    }

    var body: some View {
        Group {
            if popupManager.isExpanded {
                expandedEditor
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.95).combined(with: .opacity),
                        removal: .scale(scale: 0.95).combined(with: .opacity)
                    ))
            } else {
                collapsedNotification
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .onAppear {
            // Auto-focus the popup when it appears so first click works
            isTextEditorFocused = true
        }
        .onChange(of: popupManager.isExpanded) { _, expanded in
            withAnimation(.easeInOut(duration: 0.3)) {
                windowSize = expanded ?
                    CGSize(width: 400, height: 280) :  // Editor size
                    CGSize(width: 340, height: 72)    // Notification size
            }
        }
        .frame(width: windowSize.width, height: windowSize.height)
        // Use proper SwiftUI material background instead of glassEffect
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var collapsedNotification: some View {
        Button(action: {
            popupManager.expandEditor()
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
//            .frame(width: 340, height: 72)
        }
        .buttonStyle(PopButtonStyle())
        .allowsWindowActivationEvents()
    }

    private var expandedEditor: some View {
        PopEditor(
            text: popupManager.currentText,
            isDragging: isDragging,
            onConfirm: { plainText in
                popupManager.confirmEdit(plainText)
                dismiss()
            },
            onCancel: {
                popupManager.cancelEdit()
                dismiss()
            }
        )
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
                    // More sensitive drag gesture for styling effects
                    DragGesture(minimumDistance: 1)
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
        }
    }

}
