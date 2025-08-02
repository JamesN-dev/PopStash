//
//  RichText.swift
//  PopStash
//
//  Created by atetraxx on 8/1/25.
//

import SwiftUI
import Foundation

@MainActor
@Observable
final class RichText: Identifiable {
    let id = UUID()
    
    var text: AttributedString
    
    init(plainText: String) {
        self.text = AttributedString(plainText)
    }
    
    var plainText: String {
        String(text.characters)
    }
    
    func toggleBold() {
        // Simple implementation - just toggle for whole text for now
        if text.font == .body.bold() {
            text.font = .body
        } else {
            text.font = .body.bold()
        }
    }
    
    func toggleItalic() {
        // Simple implementation - just toggle for whole text for now  
        if text.font == .body.italic() {
            text.font = .body
        } else {
            text.font = .body.italic()
        }
    }
    
    func setTextColor(_ color: Color) {
        text.foregroundColor = color
    }
    
    var currentFormatting: TextFormatting {
        TextFormatting(
            isBold: text.font == .body.bold(),
            isItalic: text.font == .body.italic(),
            textColor: text.foregroundColor
        )
    }
}