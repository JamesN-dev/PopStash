//
//  NotificationPopupView 2.swift
//  PopStash
//
//  Created by atetraxx on 7/31/25.
//


// NotificationPopupView.swift
import SwiftUI

struct NotificationPopupView: View {
    @Bindable var popupManager: NotificationPopupManager
    @State private var editText: String = ""
    @State private var isHovered = false
    @FocusState private var isTextEditorFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
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
            editText = popupManager.currentText
            print("🎨 NotificationPopupView appeared - isExpanded: \(popupManager.isExpanded), isShowing: \(popupManager.isShowing)")
        }
        .onChange(of: popupManager.currentText) { oldValue, newValue in
            // FIXED: Sync editText when currentText changes
            editText = newValue
            print("🔄 Text updated: \(newValue.prefix(30))...")
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
        .frame(width: 340, height: 72)
    }
    
    private var expandedEditor: some View {
        VStack(spacing: 0) {
            // Simple header bar
            HStack {
                Text("Edit Clipboard")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: {
                    popupManager.dismissPopup()
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Clean text editor - like Notepad
            TextEditor(text: $editText)
                .font(.system(size: 13, weight: .regular))
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.textBackgroundColor))
                .focused($isTextEditorFocused)
                .onAppear {
                    isTextEditorFocused = true
                }
            
            // Simple bottom bar with buttons
            HStack(spacing: 8) {
                Button("Cancel") {
                    popupManager.cancelEdit()
                    dismiss()
                }
                .keyboardShortcut(.escape, modifiers: [])
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button("Save") {
                    popupManager.confirmEdit(editText)
                    dismiss()
                }
                .keyboardShortcut(.return, modifiers: [])
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .background(Color(NSColor.windowBackgroundColor))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color(NSColor.separatorColor), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        .frame(width: 400, height: 200)
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
        ZStack {
            if popupManager.isShowing {
                Color.clear
                    .ignoresSafeArea(.all)
                
                VStack {
                    HStack {
                        Spacer()
                        NotificationPopupView(popupManager: popupManager)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.9)),
                                removal: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.95))
                            ))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
        }
        .allowsHitTesting(popupManager.isShowing)
    }
}
