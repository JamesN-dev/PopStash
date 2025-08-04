# PopStash TODO

## HIGH PRIORITY

### macOS Quick Look Implementation

[ ] **#1 HIGH: Implement macOS Finder-style Quick Look for clipboard items**

- Status: NEW FEATURE - Replace current MetadataView with native Quick Look experience
- Requirements:
  - Space key triggers fullscreen Quick Look overlay
  - Pixel-perfect native macOS styling (adapts to dark/light mode)
  - Header: [X] [⤢] "PopStash Item #N" title layout
  - Actions: [Share] [Open with PopEditor] buttons
  - ESC key to close overlay
- Impact: Native Mac user experience, familiar interaction patterns
- Implementation: Custom SwiftUI overlay matching system Quick Look appearance

[ ] **#1 HIGH: Add keyboard navigation to clipboard list**

- Arrow keys (up/down) to navigate clipboard items
- Space bar to trigger Quick Look preview
- Enter key to copy selected item
- Option+click to open PopEditor for editing

[ ] **#1 MED: Create Finder-style metadata sidebar panel**

- Show Created/Modified timestamps
- Display content type and character count
- Source application info (when available)
- Pin/unpin functionality

[ ] **#1 LOW: Polish clipboard list appearance**

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

[ ] **#1 PROBLEM: X close button not working in clipboardview**

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
