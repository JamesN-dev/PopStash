import AppKit
// SwiftHotkey.swift
import SwiftUI

/// SwiftUI-friendly global hotkey manager.
/// Designed for macOS 15.4+ and App Store compatibility.
@Observable
final class SwiftHotkey {
    /// The key to listen fo
    let key: KeyboardKey

    /// The modifier flags (e.g., .option) - now using NSEvent.ModifierFlags
    let modifiers: NSEvent.ModifierFlags

    /// Whether the hotkey is currently enabled
    var isEnabled = true {
        didSet { updateMonitoring() }
    }

    /// Closure called when the hotkey is pressed
    private var onTriggered: () -> Void

    /// Internal monitor reference
    private var monitor: Any?

    /// Initialize with a key, modifiers, and action
    init(
        key: KeyboardKey,
        modifiers: NSEvent.ModifierFlags = [],
        isEnabled: Bool = true,
        onTriggered: @escaping () -> Void
    ) {
        self.key = key
        self.modifiers = modifiers
        self.isEnabled = isEnabled
        self.onTriggered = onTriggered

        if isEnabled {
            startMonitoring()
        }
    }

    /// Start monitoring the global key event
    private func startMonitoring() {
        guard monitor == nil else { return }

        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            guard self.shouldTrigger(from: event) else { return }
            self.onTriggered()
        }
    }

    /// Stop monitoring
    private func stopMonitoring() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    /// Check if the event matches our hotkey
    private func shouldTrigger(from event: NSEvent) -> Bool {
        guard isEnabled else { return false }

        // Must match key
        guard event.keyCode == key.rawValue else { return false }

        // Must match modifiers exactly
        let eventModifiers = event.modifierFlags.subtracting(.deviceIndependentFlagsMask)
        let requiredModifiers = modifiers.subtracting(.deviceIndependentFlagsMask)

        return eventModifiers == requiredModifiers
    }

    /// Update monitoring state based on `isEnabled`
    private func updateMonitoring() {
        if isEnabled {
            startMonitoring()
        } else {
            stopMonitoring()
        }
    }

    /// Deinit cleans up
    deinit {
        stopMonitoring()
    }
}

// MARK: - KeyboardKey (Type-Safe Key Codes)
/// A type-safe wrapper for common virtual key codes
enum KeyboardKey: UInt16 {
    case a = 0x00
    case b = 0x0B
    case c = 0x08
    case v = 0x09
    case x = 0x07
    case z = 0x06
    // Add more as needed
}


