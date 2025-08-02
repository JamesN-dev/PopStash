//
//  TextFormat.swift
//  PopStash
//
//  Created by atetraxx on 8/1/25.
//

import SwiftUI
import Foundation

// MARK: - Text Formatting State
struct TextFormatting {
    let isBold: Bool
    let isItalic: Bool
    let textColor: Color?
}

// MARK: - Clipboard Attribute Scopes
extension AttributeScopes {
    /// Attributes for basic clipboard text formatting
    struct ClipboardTextAttributes: AttributeScope {
        /// Font attribute for bold/italic/size
        let font: AttributeScopes.SwiftUIAttributes.FontAttribute
        /// Foreground color attribute
        let foregroundColor: AttributeScopes.SwiftUIAttributes.ForegroundColorAttribute
        /// Custom clipboard metadata
        let custom: CustomClipboardAttributes
    }
}

extension AttributeScopes {
    /// Custom attributes specific to clipboard content
    struct CustomClipboardAttributes: AttributeScope {
        /// Mark text as important/highlighted
        let isHighlighted: HighlightAttribute
        /// Source application metadata
        let sourceApp: SourceAppAttribute
    }
}

// MARK: - Custom Attribute Definitions

/// Attribute for highlighting important text in clipboard
struct HighlightAttribute: CodableAttributedStringKey {
    typealias Value = Bool
    
    static let name = "PopStash.HighlightAttribute"
    static let inheritedByAddedText: Bool = false
}

/// Attribute for storing source application info
struct SourceAppAttribute: CodableAttributedStringKey {
    typealias Value = String
    
    static let name = "PopStash.SourceAppAttribute"
    static let inheritedByAddedText: Bool = false
    static let invalidationConditions: Set<AttributedString.AttributeInvalidationCondition>? = [.textChanged]
}

// MARK: - Attribute Dynamic Lookup Extension
extension AttributeDynamicLookup {
    /// Make custom attributes available via dynamic lookup
    subscript<T: AttributedStringKey>(
        dynamicMember keyPath: KeyPath<AttributeScopes.CustomClipboardAttributes, T>
    ) -> T {
        self[T.self]
    }
}