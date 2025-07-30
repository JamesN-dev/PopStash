//
//  PopEditorView.swift
//  PopStash
//
//  Created by Blazing Fast Labs on 7/29/25.
//

import SwiftUI

struct PopEditorView: View {
    @State private var bufferText: String
    
    var onConfirm: (String) -> Void
    var onCancel: () -> Void

    // Custom initializer to set the initial text and actions.
    init(initialText: String, onConfirm: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        _bufferText = State(initialValue: initialText)
        self.onConfirm = onConfirm
        self.onCancel = onCancel
    }

    var body: some View {
        VStack(spacing: 12) {
            Text("Edit Clipboard")
                .font(.headline)
            TextEditor(text: $bufferText)
                .border(Color.gray.opacity(0.2), width: 1)
                .frame(height: 100)
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape, modifiers: [])
                Spacer()
                Button("Confirm") {
                    onConfirm(bufferText)
                }
                .keyboardShortcut(.return, modifiers: [])
            }
        }
        .padding()
        .frame(width: 400)
    }
}
