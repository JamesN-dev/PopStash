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
    var popupManager: NotificationPanelManager
    // Injected preferences (optional to avoid tight coupling in init)
    var preferencesManager: PreferencesManager?
    // ID of most recently inserted/added history item (not persisted)
    var lastAddedItemId: UUID? = nil

    // Flag to prevent moving items to top when we copy them programmatically
    private var isInternalCopy = false

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
        // Initialize popupManager without back-reference first
        self.popupManager = NotificationPanelManager()
        loadHistory()
        setupKeyboardShortcuts()
        startClipboardMonitoring()
    }

    // Allow app to inject preferences after creation
    func setPreferencesManager(_ preferences: PreferencesManager) {
        self.preferencesManager = preferences
        // Also pass to popup manager so it can inject environment objects
        self.popupManager.setPreferencesManager(preferences)
    }

    // Public: Re-apply ordering (used when preferences change)
    func applyOrdering() {
        reorderForPinState()
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
        let result = AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedUIElementAttribute as CFString, &focusedElement)

        guard result == .success, let element = focusedElement else {
            logger.debug("Could not get focused UI element - result: \(result.rawValue)")
            return nil
        }

        // Try multiple approaches to get selected text
        let axElement = element as! AXUIElement

        // Method 1: Try AXSelectedText directly
        var selectedText: CFTypeRef?
        var textResult = AXUIElementCopyAttributeValue(axElement, kAXSelectedTextAttribute as CFString, &selectedText)

        if textResult == .success, let text = selectedText as? String, !text.isEmpty {
            logger.info("Found selected text via AXSelectedText: '\(text.prefix(50))'")
            return text
        }

        // Method 2: Try getting the role and then text
        var role: CFTypeRef?
        let roleResult = AXUIElementCopyAttributeValue(axElement, kAXRoleAttribute as CFString, &role)

        if roleResult == .success, let roleString = role as? String {
            logger.debug("Focused element role: \(roleString)")

            // For text fields, text areas, and web areas, try again
            if roleString.contains("Text") || roleString.contains("WebArea") {
                textResult = AXUIElementCopyAttributeValue(axElement, kAXSelectedTextAttribute as CFString, &selectedText)
                if textResult == .success, let text = selectedText as? String, !text.isEmpty {
                    logger.info("Found selected text via role-based approach: '\(text.prefix(50))'")
                    return text
                }
            }
        }

        // Method 3: Try getting text from parent elements (for complex UI)
        var parent: CFTypeRef?
        let parentResult = AXUIElementCopyAttributeValue(axElement, kAXParentAttribute as CFString, &parent)

        if parentResult == .success, let parentElement = parent {
            textResult = AXUIElementCopyAttributeValue(parentElement as! AXUIElement, kAXSelectedTextAttribute as CFString, &selectedText)
            if textResult == .success, let text = selectedText as? String, !text.isEmpty {
                logger.info("Found selected text via parent element: '\(text.prefix(50))'")
                return text
            }
        }

        logger.debug("No selected text found - textResult: \(textResult.rawValue)")
        return nil
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

        // Quick paste shortcuts removed - not great shortcuts
    }

    // MARK: - App Store Safe Clipboard Monitoring

    private func startClipboardMonitoring() {
        self.lastChangeCount = NSPasteboard.general.changeCount
        logger.info("Starting clipboard monitoring - initial changeCount: \(self.lastChangeCount)")

        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
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
        // Skip if this is an internal copy (user clicked an item)
        if isInternalCopy {
            isInternalCopy = false
            return
        }

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

    // Quick paste function removed - shortcuts were not great

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
        // When saving from PopEditor, mark source as PopStash but keep original source
        let currentSource = (appName: "PopStash", bundleID: "com.popstash.app")
        // If the last item exists, use its original source; else fall back to frontmost
        var originalSource: (String?, String?) = frontmostAppInfo()
        if let last = history.first {
            originalSource = (last.originalSourceAppName ?? last.sourceAppName, last.originalSourceAppBundleID ?? last.sourceAppBundleID)
        }
        // Create an item explicitly to set both current and original source
        let item = ClipboardItem(
            content: .text(text),
            sourceAppName: currentSource.appName,
            sourceAppBundleID: currentSource.bundleID,
            originalSourceAppName: originalSource.0,
            originalSourceAppBundleID: originalSource.1
        )
        // De-duplicate by content
        if let i = history.firstIndex(where: { $0.content == item.content }) {
            history.remove(at: i)
        }
        history.insert(item, at: 0)
        lastAddedItemId = item.id
        reorderForPinState()
        pruneToMaxHistory()
    }

    func addToHistory(_ content: ClipContent) {
        if let i = history.firstIndex(where: { $0.content == content }) {
            history.remove(at: i)
        }
    let (appName, bundleID) = frontmostAppInfo()
    let item = ClipboardItem(content: content, sourceAppName: appName, sourceAppBundleID: bundleID)
        history.insert(item, at: 0)
        lastAddedItemId = item.id
        reorderForPinState() // Ensure pinned ordering maintained
    pruneToMaxHistory()
    }

    func copyItemToClipboard(item: ClipboardItem, asPlainText: Bool? = nil) {
        isInternalCopy = true // Set flag to prevent moving to top
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.content {
        case .text(let text):
            if asPlainText ?? false {
                pb.setString(text, forType: .string) // plain text only
            } else {
                // Current behavior: write standard string type
                // If rich types are added later, extend here.
                pb.setString(text, forType: .string)
            }
        case .image(let data):
            pb.setData(data, forType: .tiff)
        }
    }

    func copyItemToClipboardAndMoveToTop(item: ClipboardItem, asPlainText: Bool? = nil) {
        // First copy to clipboard
        copyItemToClipboard(item: item, asPlainText: asPlainText)
        // Then move to top of history
        if let index = history.firstIndex(where: { $0.id == item.id }) {
            let movedItem = history.remove(at: index)
            history.insert(movedItem, at: 0)
        }
    }

    func deleteItem(with id: UUID) {
        history.removeAll { $0.id == id }
    }

    func deleteItems(with ids: Set<UUID>) {
        history.removeAll { ids.contains($0.id) }
    }

    func clearHistory() {
        history.removeAll()
    }

    // MARK: - Query Helpers

    /// Return history filtered by search text against previewText
    func filteredHistory(matching searchText: String) -> [ClipboardItem] {
        guard !searchText.isEmpty else { return history }
        return history.filter { $0.previewText.localizedCaseInsensitiveContains(searchText) }
    }

    func togglePin(for item: ClipboardItem) {
        if let i = history.firstIndex(where: { $0.id == item.id }) {
            history[i].isPinned.toggle()
            if history[i].isPinned {
                history[i].pinnedAt = Date()
                history[i].unpinnedAt = nil
            } else {
                history[i].pinnedAt = nil
                history[i].unpinnedAt = Date() // Mark when it was unpinned for optional recency boost
            }
            reorderForPinState()
        }
    }

    private func reorderForPinState() {
        let pinned = history.filter { $0.isPinned }.sorted { (a, b) in
            switch (a.pinnedAt, b.pinnedAt) {
            case let (da?, db?): return da < db
            case (_?, nil): return true
            case (nil, _?): return false
            default: return a.dateAdded > b.dateAdded
            }
        }
        // Unpinned ordering depends on preference
        let moveUnpinnedToTop = preferencesManager?.unpinMovesToTop ?? false
        let unpinned = history.filter { !$0.isPinned }.sorted { a, b in
            if moveUnpinnedToTop {
                // Use unpinnedAt if available to treat recently unpinned as most recent
                let ar = a.unpinnedAt ?? a.dateAdded
                let br = b.unpinnedAt ?? b.dateAdded
                return ar > br
            } else {
                // Strict chronological by original dateAdded
                return a.dateAdded > b.dateAdded
            }
        }
        history = pinned + unpinned
    }

    func openEditorWith(item: ClipboardItem) {
        if case .text(let text) = item.content {
            popupManager.showPopup(
                with: text,
                onConfirm: { [weak self] editedText in
                    // Preserve the item's original source when saving from editor
                    self?.finalizeEditedString(fromOriginal: item, editedText)
                },
                onCancel: { /* Do nothing - keep original item */ }
            )
        }
    }

    // Save edited text marking PopStash as current source while preserving the original item's source
    func finalizeEditedString(fromOriginal originalItem: ClipboardItem, _ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)

        let currentSource = (appName: "PopStash", bundleID: "com.popstash.app")
        let originalName = originalItem.originalSourceAppName ?? originalItem.sourceAppName
        let originalBundle = originalItem.originalSourceAppBundleID ?? originalItem.sourceAppBundleID

        let item = ClipboardItem(
            content: .text(text),
            sourceAppName: currentSource.appName,
            sourceAppBundleID: currentSource.bundleID,
            originalSourceAppName: originalName,
            originalSourceAppBundleID: originalBundle
        )

        if let i = history.firstIndex(where: { $0.content == item.content }) {
            history.remove(at: i)
        }
        history.insert(item, at: 0)
        lastAddedItemId = item.id
        reorderForPinState()
        pruneToMaxHistory()
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
            pruneToMaxHistory()
        } catch {
            print("Load error: \(error)")
        }
    }

    private func frontmostAppInfo() -> (String?, String?) {
        if let app = NSWorkspace.shared.frontmostApplication {
            return (app.localizedName, app.bundleIdentifier)
        }
        return (nil, nil)
    }

    // Keep history length within user preference
    func pruneToMaxHistory() {
        let maxItems = preferencesManager?.maxHistoryItems ?? 100
        if history.count > maxItems {
            history = Array(history.prefix(maxItems))
        }
    }
}
