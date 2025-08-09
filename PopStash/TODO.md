# PopStash TODO

## HIGH PRIORITY BUGS

[ ] **PopEditor editing bugs** - Multiple critical issues with item editing:

- Original item remains when editing (should be replaced)
- Pinned items move to top when edited (should stay in pinned position)
- Duplicate items created when using Enter + Save to Clipboard
- PopEditor treats edits as new captures instead of updating existing items

[x] **Add focus indicator for selected items** - Implemented subtle accent stroke focus ring around active row (keyboard navigation) while preserving hover differentiation

[ ] **Make MetadataView editable** - Add TextEditor functionality to allow quick text editing directly in metadata panel, similar to PopEditor behavior

## HIGH PRIORITY

### Rich Text Implementation

[ ] **HIGH: Add rich text format tracking and dynamic toast messages**

- Status: FOUNDATION NEEDED - Currently all text is stored as plain text String
- Requirements:
  - Add property to ClipboardItem to track original format (rich vs plain)
  - Update clipboard capture to detect and preserve rich text formatting
  - Modify toast messages to show actual format: "Copied as Rich Text" vs "Copied as Plain Text"
  - Ensure Opt+click still forces plain text regardless of original format
- Current: Both regular and Opt+click show "Copied as Plain Text" since rich text not implemented
- Implementation: Extend ClipContent enum or add format tracking property

### macOS Quick Look Implementation

[x] **#1 HIGH: Implement macOS Finder-style Quick Look for clipboard items**

- Status: NEW FEATURE - Replace current MetadataView with native Quick Look experience
- Requirements:
  - Space key triggers fullscreen Quick Look overlay
  - Pixel-perfect native macOS styling (adapts to dark/light mode)
  - Header: [X] [⤢] "PopStash Item #N" title layout
  - Actions: [Share] [Open with PopEditor] buttons
  - ESC key to close overlay
- Impact: Native Mac user experience, familiar interaction patterns
- Implementation: Custom SwiftUI overlay matching system Quick Look appearance

[x] **#1 HIGH: Add keyboard navigation to clipboard list**

- Arrow keys (up/down) to navigate clipboard items
- Space bar to trigger Quick Look preview
- Enter key to copy selected item
- Option+click to open PopEditor for editing

[x] **#1 MED: Create Finder-style metadata sidebar panel**

- Show Created/Modified timestamps
- Display content type and character count
- Source application info (when available)
- Pin/unpin functionality

[x] **#1 LOW: Polish clipboard list appearance**

- Add divider lines between clipboard items
- Reduce left padding on items
- Change background to .regularMaterial
- More Finder-like spacing and styling

### Window & UI Critical Issues

[ ] **#1 HIGH: Fix PopEditor blue drag outline**

- Status: Blue outline drag styling needs to be restored/fixed
- Impact: PopEditor drag feedback is missing or broken
- Implementation: Restore blue outline with responsive 1pt sensitivity and window-level dragging

[ ] **#1 HIGH: Add sticky notes functionality to PopEditor**

- Status: NEW FEATURE REQUEST - Add option to make PopEditor persist like Mac Notes
- Requirement: Toggle button or menu option to keep editor open after save/cancel
- Impact: Enhanced workflow for users who want persistent text editing
- Implementation: Add sticky mode state, modify close behavior

[x] **REMOVED: X close button** - Decided to remove instead of fix

[ ] **HIGH: Add live clipboard history update while typing**

- Status: Currently only updates on confirm/cancel
- Impact: Poor UX - user can't see real-time preview of changes
- Requirement: Update clipboard history as user types in editor
- Implementation: Bind editor text to history item in real-time

### Core Functionality Fixes

- [ ] **MED-HIGH: Fix accessibility permission handling**

  - Status: Smart detection always fails with "Could not get focused UI element"
  - Impact: Forces fallback to Cmd+C simulation every time
  - Current: App should request permission but smart detection still fails
  - Next: Debug AXIsProcessTrusted() and permission flow

- [ ] **MED-HIGH: Debug why popup sometimes doesn't show**
  - Status: Popup fails to appear after some time has passed with it installed

## MEDIUM PRIORITY

### UX Improvements

- [ ] Image clipboard support
- [ ] Advanced settings panel (skeleton setup but not wired)
- [ ] Custom keyboard shortcut configuration

- [ ] **MED: Add multi-monitor positioning support**
  - Status: Currently uses `context.defaultDisplay` which only targets main screen
  - Impact: Popup always appears on primary display instead of active screen
  - Next: Research modern SwiftUI methods for detecting active screen and cursor position
  - Goal: Replace `defaultDisplay.visibleRect` with dynamic screen detection

## LOW PRIORITY

### Technical Cleanup

- [ ] **LOW: Fix metal library warnings**

  - Error: "Unable to open mach-O at path: default.metallib Error:2"
  - Impact: Console noise, no functional impact
  - Investigation: May be related to SwiftUI rendering pipeline

- [ ] **LOW: Fix ViewBridge errors**

  - Error: "ViewBridge to RemoteViewService Terminated: Error Domain=com.apple.ViewBridge Code=18"
  - Impact: Console noise during window operations
  - Investigation: Related to SwiftUI window lifecycle

- [ ] **FRAGILE: Window draggable and editable**
  - Status: Currently working BUT very fragile - had to revert from `.plain` to `.hiddenTitleBar`
  - Problem: `.plain` = no buttons but kills drag/edit, `.hiddenTitleBar` = drag/edit works but shows buttons
  - Issue: No stable solution that gives us both button-free AND draggable/editable
  - Risk: Any window style change breaks either functionality or appearance

---

## IMPLEMENTATION NOTES

### Window Position Fix Strategy

1. **Persistent Location**: Store fixed notification position, ignore drag state
2. **Reset on Close**: Snap window position back when editor closes
3. **Multiple Popups**: Decide if notifications can spawn while editor is open
4. **Sticky Mode**: Add toggle for persistent editor like Mac Notes

### Window Button Removal Approaches

1. **Custom NSWindow**: Subclass NSWindow, override `styleMask`
2. **WindowToolbarStyle**: Try `.unified`, `.unifiedCompact`, `.expanded`
3. **SwiftUI Modifiers**: Research lesser-known window appearance modifiers
4. **Programmatic**: Use NSWindow appearance APIs post-creation

### Live Update Implementation

```swift
// In NotificationPopupView, bind text changes
.onChange(of: editedText) { _, newText in
    // Update clipboard manager history in real-time
    clipboardManager.updateCurrentHistoryItem(newText)
}
```

### Positioning Debug Strategy

- Log actual `displayBounds` values
- Compare with screen resolution and coordinate systems
- Test on multiple monitor setups
- Consider menu bar height and dock positioning

---

## COMPLETED ITEMS

[x] **Preferences single-pane width + proper transition** - Enforced 320pt width with dynamic container sizing logic & conditional root view swap
[x] **Preferences header + back navigation** - Added inline header bar with chevron and title; back animates and restores history width
[x] **Search focus retention bug fixed** - Prevented selection sync from stealing focus after 3rd/4th character while typing
[x] **Top row clipping resolved** - Removed negative list padding; added slight positive offset to avoid first item underlapping toolbar
[x] **List insertion jump minimized** - Disabled implicit row animations & removed layout jitter on new captures
[x] **Focus indicator implemented** - Accent stroke ring on keyboard-focused row distinct from hover state
[x] **Multi-selection and keyboard shortcuts** - Added Delete, Cmd+A, Shift navigation, context menu bulk delete
[x] **Fixed item positioning behavior** - Internal copy flag prevents unintended reordering
[x] **Enhanced click interactions** - Shift range select, Option+click edit, press feedback
[x] **Improved keyboard shortcuts** - Proper command mappings & delete handling
[x] **Fixed multi-selection clearing**
[x] **Option+click hover hint**
[x] **MetadataView selectable text**
[x] **Consistent glass effect styling across major surfaces**
[x] **Sidebar performance optimization**
[x] **Custom glass effect implementation**
[x] **Preferences navigation refactor (removed NavigationStack)**
[x] **MAJOR: PopEditor & Notification positioning / focus fixes**
[x] **Dynamic copy toast notifications** - Added toast feedback for regular clicks showing "Copied as Plain Text" or "Copied" for images, with separate toast for Opt+click plain text copying
[x] **Removed pasteAsPlainTextByDefault preference** - Simplified UX by removing preference setting and default mode badge from MetadataView, users now have direct control via Opt+click
[x] **Streamlined MetadataView badges** - Kept item type badge (Plain/Image) showing what content IS, removed confusing default paste mode badge
[x] **All prior listed completed items preserved**
