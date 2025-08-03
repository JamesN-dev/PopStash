//
//  EditorWindowContent.swift
//  PopStash
//
//  Wrapper view for the editor window that properly manages state
//

import SwiftUI

struct EditorWindowContent: View {
    @Bindable var popupManager: NotificationPopupManager
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        PopEditor(
            text: popupManager.currentText,
            isDragging: false,
            onConfirm: { editedText in
                popupManager.confirmEdit(editedText)
                dismissWindow(id: "textEditor")
            },
            onCancel: {
                popupManager.cancelEdit()
                dismissWindow(id: "textEditor")
            }
        )
        .background(.regularMaterial)
    }
}