//
//  CarbonHotkey 2.swift
//  PopStash
//
//  Created by atetraxx on 7/31/25.
//


//
// CarbonHotkey.swift
//  PopStash
//
//  Created by Blazing Fast Labs on 7/30/25.
//

import Carbon
import Foundation

final class CarbonHotkey {
    private var hotKeyRef: EventHotKeyRef?
    private let callbackWrapper: () -> Void

    init(keyCode: UInt32, modifiers: UInt32, callback: @escaping () -> Void) {
        self.callbackWrapper = callback

        // Register an event handler for hotkey presses.
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed))

        let callbackPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, _, userInfo) -> OSStatus in
                let instance = Unmanaged<CarbonHotkey>.fromOpaque(userInfo!).takeUnretainedValue()
                instance.callbackWrapper()
                return noErr
            }, 1, &eventType, callbackPointer, nil)

        // Define a unique signature for the hotkey (four ASCII chars) - now using let
        let hotKeyID = EventHotKeyID(signature: OSType("CLIP".fourCharCode), id: 1)

        RegisterEventHotKey(
            keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    deinit {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }
}

extension String {
    fileprivate var fourCharCode: FourCharCode {
        return utf16.reduce(0) { ($0 << 8) + FourCharCode($1) }
    }
}
