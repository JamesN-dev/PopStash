//
//  PopEditor.swift
//  PopStash
//
//  Created by atetraxx on 8/1/25.
//

import SwiftUI

/// Sleek plain text editor for clipboard content
struct PopEditor: View {
    @State private var text: String
    @FocusState private var isTextEditorFocused: Bool
    
    // Drag state management
    @State private var location = CGPoint(x: 200, y: 200)
    @GestureState private var startLocation: CGPoint?
    @State private var isDragging = false
    
    var onConfirm: (String) -> Void
    var onCancel: () -> Void
    
    init(text: String, onConfirm: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self._text = State(initialValue: text)
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                self.location = value.location
                isDragging = true
            }
            .onEnded { value in
                isDragging = false
            }
            .updating(self.$startLocation) { value, startLocation, transaction in
                startLocation = startLocation ?? location
            }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with title and close button
            HStack {
                Text("Text Editor")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            .contentShape(Rectangle()) // Make entire header draggable
            .gesture(drag)
            
            // Clean text editor
            TextEditor(text: $text)
                .font(.system(.body, design: .default))
                .scrollContentBackground(.hidden)
                .focused($isTextEditorFocused)
                .padding(12)
                .background(Color(NSColor.textBackgroundColor))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isTextEditorFocused = true
                    }
                }
            
            // Bottom action bar with character count
            HStack(spacing: 8) {
                Text("\(text.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.escape, modifiers: [])
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                
                Button("Save to Clipboard") {
                    onConfirm(text)
                }
                .keyboardShortcut(.return, modifiers: [.command])
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
                .strokeBorder(
                    isDragging ? Color.accentColor : Color(NSColor.separatorColor),
                    lineWidth: isDragging ? 2 : 1
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .shadow(
            color: .black.opacity(isDragging ? 0.3 : 0.2),
            radius: isDragging ? 16 : 12,
            x: 0,
            y: isDragging ? 6 : 4
        )
        .frame(width: 400, height: 280)
        .position(location)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
        .scaleEffect(isDragging ? 1.02 : 1.0)
    }
}
