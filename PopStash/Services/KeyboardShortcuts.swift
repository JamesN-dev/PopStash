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
    
    // Quick paste shortcuts for clipboard history (Option+1 through Option+9)
    static let quickPaste1 = Self("quickPaste1", default: .init(.one, modifiers: .option))
    static let quickPaste2 = Self("quickPaste2", default: .init(.two, modifiers: .option))
    static let quickPaste3 = Self("quickPaste3", default: .init(.three, modifiers: .option))
    static let quickPaste4 = Self("quickPaste4", default: .init(.four, modifiers: .option))
    static let quickPaste5 = Self("quickPaste5", default: .init(.five, modifiers: .option))
    static let quickPaste6 = Self("quickPaste6", default: .init(.six, modifiers: .option))
    static let quickPaste7 = Self("quickPaste7", default: .init(.seven, modifiers: .option))
    static let quickPaste8 = Self("quickPaste8", default: .init(.eight, modifiers: .option))
    static let quickPaste9 = Self("quickPaste9", default: .init(.nine, modifiers: .option))
}
