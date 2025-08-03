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
    let isDragging: Bool // Passed from parent for styling
    
    var onConfirm: (String) -> Void
    var onCancel: () -> Void
    
    init(text: String, isDragging: Bool, onConfirm: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self._text = State(initialValue: text)
        self.isDragging = isDragging
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 0) {
            // Clean text editor - remove all background interference
            TextEditor(text: $text)
                .font(.system(.body, design: .default))
                .scrollContentBackground(.hidden)
                .focused($isTextEditorFocused)
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    DispatchQueue.main.async {
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
            .background(.regularMaterial)
        }
        .background(.regularMaterial)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isDragging ? Color.accentColor.opacity(0.8) : Color.clear,
                    lineWidth: 2
                )
        )
        .frame(width: 400, height: 280)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
    }
    
}
