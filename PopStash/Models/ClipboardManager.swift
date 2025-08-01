// ClipboardManager.swift
import Observation
import AppKit
import CoreGraphics
import Carbon

@Observable
final class ClipboardManager {
    var history: [ClipboardItem] = [] {
        didSet { saveHistory() }
    }
    var popupManager = NotificationPopupManager() // Assuming you have this class
    
    // Store the openWindow function
    var openWindow: (() -> Void)?
    
    private var storageURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = support.appendingPathComponent("PopStash")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("history.json")
    }

    init() {
        loadHistory()
    }

    // --- THIS IS THE NEW FUNCTION THAT WAS MISSING ---
    // This is the main function called by the hotkey. It contains the logic
    // that used to be in your PopStashApp.swift file.
    func handleClipboardCapture() {
        print("--- Hotkey Triggered ---")
        let pasteboard = NSPasteboard.general
        let originalContent = pasteboard.string(forType: .string) ?? "[Clipboard was empty or not text]"
        print("Original Clipboard Content: '\(originalContent)'")

        simulateCommandC()

        // Using a longer, safer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            let newContent = pasteboard.string(forType: .string) ?? "[Clipboard is now empty or not text]"
            print("--- After Delay ---")
            print("New Clipboard Content: '\(newContent)'")
            print("Did content change? \(newContent != originalContent)")

            var textToProcess: String?

            // Determine which text to use based on the logic
            if newContent != "[Clipboard is now empty or not text]" && newContent != originalContent {
                print("✅ Logic: New text was selected and copied.")
                textToProcess = newContent
            } else if originalContent != "[Clipboard was empty or not text]" {
                print("📋 Logic: No new selection detected. Using existing content.")
                textToProcess = originalContent
            }

            if let finalText = textToProcess {
                self.addToHistory(.text(finalText))
                
                // Your existing popup logic can now be called safely
                self.popupManager.showPopup(
                    with: finalText,
                    onConfirm: { editedText in self.finalizeEditedString(editedText) },
                    onCancel: { self.addToHistory(.text(finalText)) }
                )
                
                // Open the popup window - this needs to be called on the main queue
                DispatchQueue.main.async {
                    self.openWindow?()
                }
                
                // Note: Opening a window from a background class is complex.
                // Your current method of using @Environment(\.openWindow) won't work here.
                // For now, the popupManager will handle showing the UI.
            } else {
                print("⚠️ Logic: No text to process.")
            }
        }
    }

    // --- THIS IS THE HELPER FUNCTION FOR THE ABOVE ---
    private func simulateCommandC() {
        print("⚙️ Simulating Command+C press...")
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        print("✔️ Command+C simulation sent.")
    }

    // --- ALL OF YOUR EXISTING FUNCTIONS ---
    // Your 'captureCurrentClipboard' function is no longer called by the hotkey,
    // but we can leave it in case it's used elsewhere.
    
    func captureCurrentClipboard() {
        let pb = NSPasteboard.general
        guard let types = pb.types else { return }
        guard types.contains(.string) || types.contains(.tiff) else { return }

        if let string = pb.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !string.isEmpty {
            popupManager.showPopup(
                with: string,
                onConfirm: { [weak self] edited in self?.finalizeEditedString(edited) },
                onCancel: { [weak self] in self?.addToHistory(.text(string)) }
            )
            
            // Open the popup window - this needs to be called on the main queue
            DispatchQueue.main.async {
                self.openWindow?()
            }
        }
    }

    func finalizeEditedString(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
        addToHistory(.text(text))
    }

    func addToHistory(_ content: ClipContent) {
        if let i = history.firstIndex(where: { $0.content == content }) {
            history.remove(at: i)
        }
        let item = ClipboardItem(content: content, sourceAppName: nil, sourceAppBundleID: nil)
        history.insert(item, at: 0)
    }

    func copyItemToClipboard(item: ClipboardItem) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.content {
        case .text(let text):
            pb.setString(text, forType: .string)
        case .image(let data):
            pb.setData(data, forType: .tiff)
        }
    }

    func deleteItem(with id: UUID) {
        history.removeAll { $0.id == id }
    }

    func clearHistory() {
        history.removeAll()
    }

    func togglePin(for item: ClipboardItem) {
        if let i = history.firstIndex(where: { $0.id == item.id }) {
            history[i].isPinned.toggle()
        }
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            try data.write(to: storageURL)
        } catch {
            print("Save error: \(error)")
        }
    }

    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        do {
            let data = try Data(contentsOf: storageURL)
            history = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Load error: \(error)")
        }
    }
}
