import Foundation
import AppKit

// --- FIX 1: The enum is now Equatable AND Codable ---
enum ClipContent: Equatable, Codable, Hashable {
    case text(String)
    case image(Data)
}

struct ClipboardItem: Identifiable, Equatable, Codable, Hashable {

    // --- FIX 2: The 'id' no longer has a default value here ---
    let id: UUID
    let content: ClipContent
    let dateAdded: Date

    var isPinned: Bool = false
    var pinnedAt: Date? = nil // New: preserves order items were pinned
    var unpinnedAt: Date? = nil // New: optional recency boost for unpinned behavior
    let sourceAppName: String?
    let sourceAppBundleID: String?
    // Track original source when content was edited in PopStash
    let originalSourceAppName: String?
    let originalSourceAppBundleID: String?

    // Helper property for UI text preview
    var previewText: String {
        switch content {
        case .text(let string):
            return string
        case .image:
            return "Image"
        }
    }

    // Placeholder item for when no items exist
    static let placeholder = ClipboardItem(
        content: .text("No items available"),
        sourceAppName: "PopStash",
        sourceAppBundleID: "com.popstash.app",
        originalSourceAppName: "PopStash",
        originalSourceAppBundleID: "com.popstash.app"
    )

    // Helper property to get an NSImage from data
    var image: NSImage? {
        switch content {
        case .text:
            return nil
        case .image(let data):
            return NSImage(data: data)
        }
    }

    // --- FIX 2 (cont.): We create the ID in our custom initializer ---
    // This initializer is for creating brand new items.
    init(content: ClipContent, sourceAppName: String?, sourceAppBundleID: String?, originalSourceAppName: String? = nil, originalSourceAppBundleID: String? = nil) {
        self.id = UUID() // The new, unique ID is created here.
        self.content = content
        self.dateAdded = Date() // Current timestamp
        self.sourceAppName = sourceAppName
        self.sourceAppBundleID = sourceAppBundleID
        // If original source not provided, default to current source
        self.originalSourceAppName = originalSourceAppName ?? sourceAppName
        self.originalSourceAppBundleID = originalSourceAppBundleID ?? sourceAppBundleID
    }

    // This initializer is for loading saved items from the JSON file.
    // It makes sure we can still load old data that doesn't have the new properties.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // It decodes the saved ID from the file instead of creating a new one.
        self.id = try container.decode(UUID.self, forKey: .id)
        self.content = try container.decode(ClipContent.self, forKey: .content)
        self.dateAdded = try container.decodeIfPresent(Date.self, forKey: .dateAdded) ?? Date() // Default to now for old items
        self.isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        self.pinnedAt = try container.decodeIfPresent(Date.self, forKey: .pinnedAt) // may be nil for legacy
        self.unpinnedAt = try container.decodeIfPresent(Date.self, forKey: .unpinnedAt)
    self.sourceAppName = try container.decodeIfPresent(String.self, forKey: .sourceAppName)
    self.sourceAppBundleID = try container.decodeIfPresent(String.self, forKey: .sourceAppBundleID)
    self.originalSourceAppName = try container.decodeIfPresent(String.self, forKey: .originalSourceAppName) ?? self.sourceAppName
    self.originalSourceAppBundleID = try container.decodeIfPresent(String.self, forKey: .originalSourceAppBundleID) ?? self.sourceAppBundleID
    }

    // We explicitly list all properties for Codable to use.
    private enum CodingKeys: String, CodingKey {
        case id, content, dateAdded, isPinned, pinnedAt, unpinnedAt, sourceAppName, sourceAppBundleID, originalSourceAppName, originalSourceAppBundleID
    }
}
