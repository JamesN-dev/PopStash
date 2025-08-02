// ClipboardManager.swift
import Observation
import AppKit
import CoreGraphics
import Carbon
import KeyboardShortcuts
import OSLog
import ApplicationServices

private let logger = Logger(subsystem: "com.popstash.app", category: "clipboard")

@Observable
final class ClipboardManager {
    var history: [ClipboardItem] = [] {
        didSet { saveHistory() }
    }
    var popupManager = NotificationPopupManager()
    
    // Clipboard monitoring
    private var lastChangeCount: Int = 0
    private var monitoringTimer: Timer?
    
    private var storageURL: URL {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = support.appendingPathComponent("PopStash")
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        return appDir.appendingPathComponent("history.json")
    }

    init() {
        loadHistory()
        setupKeyboardShortcuts()
        startClipboardMonitoring()
    }

    // MARK: - Accessibility Permission Management
    
    /// Check if the app has Accessibility permission
    private func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// Request Accessibility permission from the user
    private func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
    
    /// Try to get selected text directly from the focused UI element (Pastebot-style)
    private func getSelectedText() -> String? {
        // Get the system-wide UI element
        let systemWideElement = AXUIElementCreateSystemWide()
        
        // Get the focused UI element
        var focusedElement: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWideElement, "AXFocusedUIElement" as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement else {
            logger.debug("Could not get focused UI element")
            return nil
        }
        
        // Try to get selected text from the focused element
        var selectedText: CFTypeRef?
        let textResult = AXUIElementCopyAttributeValue(element as! AXUIElement, "AXSelectedText" as CFString, &selectedText)
        
        guard textResult == .success, let text = selectedText as? String, !text.isEmpty else {
            logger.debug("No selected text found")
            return nil
        }
        
        logger.info("Found selected text: '\(text.prefix(50))'")
        return text
    }

    private func setupKeyboardShortcuts() {
        logger.info("Setting up keyboard shortcuts")
        
        KeyboardShortcuts.onKeyUp(for: .primaryCapture) { [weak self] in
            logger.debug("Primary capture shortcut triggered")
            self?.handleClipboardCapture()
        }
        
        KeyboardShortcuts.onKeyUp(for: .secondaryAccess) { [weak self] in
            logger.debug("Secondary access shortcut triggered")
            self?.captureCurrentClipboard()
        }
        
        // Quick paste shortcuts
        KeyboardShortcuts.onKeyUp(for: .quickPaste1) { [weak self] in
            self?.quickPaste(index: 0)
        }
        
        KeyboardShortcuts.onKeyUp(for: .quickPaste2) { [weak self] in
            self?.quickPaste(index: 1)
        }
        
        KeyboardShortcuts.onKeyUp(for: .quickPaste3) { [weak self] in
            self?.quickPaste(index: 2)
        }
        
        KeyboardShortcuts.onKeyUp(for: .quickPaste4) { [weak self] in
            self?.quickPaste(index: 3)
        }
        
        KeyboardShortcuts.onKeyUp(for: .quickPaste5) { [weak self] in
            self?.quickPaste(index: 4)
        }
        
        KeyboardShortcuts.onKeyUp(for: .quickPaste6) { [weak self] in
            self?.quickPaste(index: 5)
        }
        
        KeyboardShortcuts.onKeyUp(for: .quickPaste7) { [weak self] in
            self?.quickPaste(index: 6)
        }
        
        KeyboardShortcuts.onKeyUp(for: .quickPaste8) { [weak self] in
            self?.quickPaste(index: 7)
        }
        
        KeyboardShortcuts.onKeyUp(for: .quickPaste9) { [weak self] in
            self?.quickPaste(index: 8)
        }
    }
    
    // MARK: - App Store Safe Clipboard Monitoring
    
    private func startClipboardMonitoring() {
        self.lastChangeCount = NSPasteboard.general.changeCount
        logger.info("Starting clipboard monitoring - initial changeCount: \(self.lastChangeCount)")
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboardChanges()
        }
    }
    
    private func checkClipboardChanges() {
        let currentChangeCount = NSPasteboard.general.changeCount
        
        if currentChangeCount != self.lastChangeCount {
            self.lastChangeCount = currentChangeCount
            addCurrentClipboardToHistory()
        }
    }
    
    private func addCurrentClipboardToHistory() {
        let pasteboard = NSPasteboard.general
        guard let text = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else { return }
        
        // Avoid duplicates - don't add if it's the same as the most recent item
        if let mostRecent = history.first,
           case .text(let recentText) = mostRecent.content,
           recentText == text {
            return
        }
        
        addToHistory(.text(text))
    }
    
    private func quickPaste(index: Int) {
        guard index < history.count else { return }
        let item = history[index]
        copyItemToClipboard(item: item)
        logger.debug("Quick pasted item \(index + 1): \(item.previewText, privacy: .private)")
    }

    // --- THIS IS THE NEW FUNCTION THAT WAS MISSING ---
    // This is the main function called by the hotkey. It contains the logic
    // that used to be in your PopStashApp.swift file.
    func handleClipboardCapture() {
        logger.debug("Hotkey triggered")
        
        // Check Accessibility permission first
        guard checkAccessibilityPermission() else {
            logger.warning("Accessibility permission not granted")
            requestAccessibilityPermission()
            return
        }
        
        var textToProcess: String?
        
        // SMART DETECTION: Try to get selected text directly first (Pastebot-style)
        if let selectedText = getSelectedText() {
            logger.info("Smart detection found selected text")
            textToProcess = selectedText
        } else {
            // Fallback 1: Try simulating Cmd+C to copy selected text
            logger.debug("Smart detection failed, trying Cmd+C simulation")
            let pasteboard = NSPasteboard.general
            let originalContent = pasteboard.string(forType: .string) ?? ""
            
            simulateCommandC()
            
            // Wait for the copy to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                let newContent = pasteboard.string(forType: .string) ?? ""
                
                if !newContent.isEmpty && newContent != originalContent {
                    logger.info("Cmd+C simulation: New text was copied")
                    self.processText(newContent)
                } else if !originalContent.isEmpty {
                    logger.info("Using existing clipboard content")
                    self.processText(originalContent)
                } else {
                    logger.warning("No text available in clipboard")
                    // Show popup with last history item or error message
                    self.showPopupWithFallbackContent()
                }
            }
            return
        }
        
        // Process the text immediately if we got it from smart detection
        if let text = textToProcess {
            processText(text)
        }
    }
    
    /// Show popup with fallback content when no text is selected
    private func showPopupWithFallbackContent() {
        let pasteboard = NSPasteboard.general
        
        // Fallback 1: Current clipboard content
        if let clipboardText = pasteboard.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !clipboardText.isEmpty {
            logger.info("Using current clipboard content for popup")
            popupManager.showPopup(
                with: clipboardText,
                onConfirm: { editedText in self.finalizeEditedString(editedText) },
                onCancel: { /* Don't add to history since it's already clipboard content */ }
            )
            return
        }
        
        // Fallback 2: Last history item
        if let lastItem = history.first {
            let text: String
            switch lastItem.content {
            case .text(let textContent):
                text = textContent
            case .image:
                text = "Image content"
            }
            logger.info("Using last history item for popup")
            popupManager.showPopup(
                with: text,
                onConfirm: { editedText in self.finalizeEditedString(editedText) },
                onCancel: { /* Don't add to history since it's already in history */ }
            )
            return
        }
        
        // Fallback 3: Show error message in popup
        let errorMessage = "No text selected and clipboard is empty.\nTry selecting some text first."
        logger.warning("No content available - showing error message")
        popupManager.showPopup(
            with: errorMessage,
            onConfirm: { _ in /* Do nothing for error message */ },
            onCancel: { /* Do nothing for error message */ }
        )
    }    
    // MARK: - History Management
    
    /// Process the captured text - show popup and add to history
    private func processText(_ text: String) {
        addToHistory(.text(text))
        
        // Show the popup with the text
        popupManager.showPopup(
            with: text,
            onConfirm: { editedText in self.finalizeEditedString(editedText) },
            onCancel: { self.addToHistory(.text(text)) }
        )
    }

    // --- THIS IS THE HELPER FUNCTION FOR THE ABOVE ---
    private func simulateCommandC() {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: true)
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_C), keyDown: false)
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
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
