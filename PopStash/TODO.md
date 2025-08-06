# PopStash TODO

## HIGH PRIORITY BUGS

[ ] **PopEditor editing bugs** - Multiple critical issues with item editing:
  - Original item remains when editing (should be replaced)
  - Pinned items move to top when edited (should stay in pinned position)
  - Duplicate items created when using Enter + Save to Clipboard
  - PopEditor treats edits as new captures instead of updating existing items

[ ] **Add focus indicator for selected items** - Need visual differentiation between hover state and actual selection focus

[ ] **Make MetadataView editable** - Add TextEditor functionality to allow quick text editing directly in metadata panel, similar to PopEditor behavior

## HIGH PRIORITY

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

[x] **Multi-selection and keyboard shortcuts** - Added Delete key to delete items, Ctrl+A to select all, Shift+Up/Down for multi-selection, visual indicators for multi-selected items. Fixed focus handling for keyboard shortcuts to work properly.
[x] **Fixed item positioning behavior** - Added internal copy flag to prevent clipboard monitoring from moving items to top when user clicks them. Only Option+C (new items) and Return key (intentional copy) move items to top.
[x] **Enhanced click interactions** - Added Shift+click for multi-selection, maintained Option+click for editing, regular click for copying without repositioning. Multi-selection clears when clicking without Shift. Added extended click feedback (150ms + 100ms delay) with scale animation and press state highlighting. Fixed edge clicking issues with improved contentShape.
[x] **Improved keyboard shortcuts** - Changed Ctrl+A to Cmd+A (more Mac-like), fixed Delete key using dedicated `.onDeleteCommand` modifier (research-backed solution), added multi-selection context menu for bulk delete operations.
[x] **Fixed multi-selection clearing** - Multi-selected items now properly clear when clicking elsewhere without holding Shift key
[x] **Option+click visual indicator** - Added hover hint showing "⌥+click to edit" for text items to indicate the Option+click functionality
[x] **MetadataView text made selectable** - Added .textSelection(.enabled) to preview text and metadata values for easy copying
[x] **PopEditor glass effect styling** - Updated PopEditor, EditorWindowContent, and NotificationPopupView to use consistent glass effect styling like ClipboardHistoryView
[x] **MAJOR FIX: Sidebar performance issue resolved** - Replaced expensive conditional view creation with persistent MetadataView, modern .slide + .scale transitions, removed .fixedSize() layout bottleneck
[x] **Custom glass effect implementation** - Added backward-compatible glass effect for macOS 15.4 that automatically upgrades to real .glassEffect() when macOS 26 is available
[x] PopEditor window styling fixed - Clean regularMaterial background matching ClipboardHistoryView
[x] PopEditor titlebar added - "PopEditor" in sleek navigationTitle with toolbar styling
[x] TextEditor made editable - Removed conflicting backgrounds/overlays blocking interaction
[x] Added input-monitoring entitlement for global Option+C shortcuts when app out of focus
[x] Architectural guidance for window drag/activation separation completed
[x] Correct modifier placement for window-level and view-level behaviors implemented
[x] PopEditor drag logic clarified: content drag is separate from window drag
[x] Fixed SwiftUI ShapeStyle.accent type errors by using .tint and Color.accentColor correctly
[x] Removed confusing popover pin button - individual clipboard item pinning works perfectly
[x] Fixed preferences navigation with NavigationPath and proper button action
[x] MenuBarExtra positioning implemented with .defaultWindowPlacement
[x] Hide item count badge when clipboard is empty (0 items)
[x] **MAJOR FIX: PopEditor positioning issue resolved** - Removed .position(location) that was moving content off-screen
[x] **PopEditor drag styling implemented** - Blue outline with responsive 1pt sensitivity and window-level dragging
[x] **PopEditor content now displays properly** - Editor shows text instead of blank window
[x] **#1 CRITICAL: Notification popup position bug after drag** - Fixed positioning corruption
[x] **Critical: Notification popup now focuses correctly** - Window-level and view-level activation modifiers separated
[x] **CRITICAL: PopEditor positioning and functionality restored** - Window-level dragging works with blue outline styling
[x] **Window mode sizing modes switching deferred** - Dynamic window mode wiring removed, only default sizing active
[x] Add hover effect toggle to preferences panel - PopButtonStyle respects system and user hover effect settings
[x] **MED: Make popup editor resizable** - Changed from fixed size to resizable
[x] **MED: Improve window positioning calculation** - Positioning logic corrected
[x] Modern `@Observable` state management implemented
[x] KeyboardShortcuts framework integrated successfully
[x] PopStashApp structure modernized with proper lifecycle
[x] AppDelegate integration completed and working
[x] Basic clipboard capture and history functionality
[x] Smart detection with Accessibility API implemented
[x] Popup window state management (show/hide) working
[x] Text editor popup functionality restored
[x] Option+C hotkey triggering and processing text
[x] Clipboard content capture and popup display working
