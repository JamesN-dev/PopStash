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
    @State private var isHovered = false
    @FocusState private var isTextEditorFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    // TODO: macOS 26.0+ - Implement smooth window morphing with windowResizeAnchor
    // Replace separate notification/editor windows with single morphing window
    // 
    // @State private var windowSize: CGSize = CGSize(width: 340, height: 72)
    // 
    // .frame(width: windowSize.width, height: windowSize.height)
    // .windowResizeAnchor(.topTrailing) // Anchor to top-right corner  
    // .onChange(of: popupManager.isExpanded) { _, expanded in
    //     withAnimation(.easeInOut(duration: 0.3)) {
    //         windowSize = expanded ? 
    //             CGSize(width: 400, height: 280) :  // Editor size
    //             CGSize(width: 340, height: 72)    // Notification size
    //     }
    // }
    //
    // This will create a smooth morphing transition from notification → editor
    // instead of opening separate windows. Much more elegant UX.
    
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
        // Use proper SwiftUI material background instead of glassEffect
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var collapsedNotification: some View {
        HStack(spacing: 14) {
            // Animated clipboard icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "doc.on.clipboard.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.accentColor)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovered)
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
                    .opacity(isHovered ? 1.0 : 0.6)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
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
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                }
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 4)
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
                .scaleEffect(isHovered ? 1.02 : 1.0)
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isHovered)
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            popupManager.expandEditor()
        }
        .focused($isTextEditorFocused)
        .frame(width: 340, height: 72)
    }
    
    private var expandedEditor: some View {
        PopEditor(
            text: popupManager.currentText,
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
    
    var body: some View {
        if popupManager.isShowing {
            NotificationPopupView(popupManager: popupManager)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                    removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.95))
                ))
        }
    }
    
}
