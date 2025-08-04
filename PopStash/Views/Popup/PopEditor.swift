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
    @State private var isStickyMode = false
    @FocusState private var isTextEditorFocused: Bool
    let initialText: String // Store the input text
    let isDragging: Bool // Passed from parent for styling

    var onConfirm: (String) -> Void
    var onCancel: () -> Void

    init(text: String, isDragging: Bool, onConfirm: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.initialText = text
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
                .textEditorStyle(.automatic)
                .writingToolsBehavior(.complete)
                .allowsHitTesting(true)
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onAppear {
                    // Give window time to settle before focusing
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        isTextEditorFocused = true
                    }
                }
                .onChange(of: initialText) { _, newText in
                    // Update text when the input parameter changes
                    text = newText
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: {
                            // Trigger Writing Tools for the focused text editor
                            NSApp.sendAction(#selector(NSTextView.showWritingTools(_:)), to: nil, from: nil)
                        }) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 13, weight: .medium))
                        }
                        .help("Writing Tools")
                    }
                }

            // Bottom action bar with character count
            HStack(spacing: 8) {
                Text("\(text.count) characters")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                // Sticky mode toggle
                Button(action: { isStickyMode.toggle() }) {
                    Image(systemName: isStickyMode ? "pin.fill" : "pin")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(isStickyMode ? Color.accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(isStickyMode ? "Disable sticky mode" : "Enable sticky mode - keep editor open after save")

                Spacer()

                Button("Cancel") {
                    if isStickyMode {
                        // In sticky mode, just clear the text instead of closing
                        text = ""
                    } else {
                        onCancel()
                    }
                }
                .keyboardShortcut(.escape, modifiers: [])
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Save to Clipboard") {
                    onConfirm(text)
                    if !isStickyMode {
                        // Only close if not in sticky mode
                    } else {
                        // In sticky mode, just clear for next input
                        text = ""
                    }
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isDragging ? Color.accentColor.opacity(0.8) : Color.clear,
                    lineWidth: 2
                )
        )
        .frame(minWidth: 400,  maxWidth: .infinity, minHeight: 280, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.2), value: isDragging)
    }

}
