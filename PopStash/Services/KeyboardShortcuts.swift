//
//  KeyboardShortcuts.swift
//  PopStash
//
//  Created by atetraxx on 8/1/25.
//

import Foundation
import KeyboardShortcuts

extension KeyboardShortcuts.Name {
    // Primary clipboard capture shortcut
    static let primaryCapture = Self("primaryCapture", default: .init(.c, modifiers: .option))
    
    // Secondary clipboard access shortcut
    static let secondaryAccess = Self("secondaryAccess", default: .init(.c, modifiers: [.shift, .option]))
}
