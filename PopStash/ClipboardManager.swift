import AppKit
import Combine

struct EditItem: Identifiable, Equatable {
    let id = UUID()
    let text: String
}

class ClipboardManager: ObservableObject {
    
    @Published var itemToEdit: EditItem? = nil
    @Published var popupManager = NotificationPopupManager()
    @Published var history: [ClipboardItem] = [] {
        didSet {
            saveHistory()
        }
    }
    
    init() {
        loadHistory()
    }
    func deleteItem(with id: UUID) {
            // This finds and removes any item from the history array whose ID matches.
            history.removeAll(where: { $0.id == id })
        }
    func finalizeEditedString(_ editedText: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(editedText, forType: .string)
        history.removeAll { $0.previewText == editedText }
        let newItem = ClipboardItem(
            content: .text(editedText),
            sourceAppName: nil,
            sourceAppBundleID: nil
        )
        history.insert(newItem, at: 0)
    }
    
    // --- THIS FUNCTION REPLACES THE OLD copyToClipboard ---
    // It can handle any type of ClipboardItem.
    func copyItemToClipboard(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        switch item.content {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let data):
            pasteboard.setData(data, forType: .tiff)
        }
    }
    
    func clearHistory() {
        history.removeAll()
    }
    
    func togglePin(for item: ClipboardItem) {
        guard let index = history.firstIndex(where: { $0.id == item.id }) else { return }
        history[index].isPinned.toggle()
    }
    
    // --- NO CHANGES NEEDED FOR SAVING AND LOADING ---
    // Our Codable setup automatically handles the new enum!
    
    private var storageURL: URL {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = supportDirectory.appendingPathComponent("PopStash")
        
        if !FileManager.default.fileExists(atPath: appDirectory.path) {
            try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return appDirectory.appendingPathComponent("history.json")
    }

    private func saveHistory() {
        do {
            let data = try JSONEncoder().encode(history)
            try data.write(to: storageURL)
        } catch {
            print("Error saving history: \(error.localizedDescription)")
        }
    }

    private func loadHistory() {
        guard FileManager.default.fileExists(atPath: storageURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: storageURL)
            history = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Error loading history: \(error.localizedDescription)")
        }
    }
    

}
