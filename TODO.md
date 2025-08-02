# PopStash TODO

## HIGH PRIORITY

### Window & UI Critical Issues
- [ ] **CRITICAL: Remove window minimize/close buttons from popup**
  - Status: Tried `.plain`, `.hiddenTitleBar`, `HiddenTitleBarWindowStyle()` - all still show buttons
  - Impact: Makes popup look unprofessional and cluttered
  - Next: Try custom NSWindow approach or windowToolbarStyle modifiers
  
- [ ] **HIGH: Position popup more to the left** 
  - Status: Currently positioned too far right despite padding adjustments
  - Current calc: `displayBounds.maxX - size.width - 80` 
  - Impact: Popup appears off-screen or awkwardly positioned
  - Next: Debug coordinate system, try fixed positioning
  
- [ ] **HIGH: Add live clipboard history update while typing**
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
  
- [ ] **MED-HIGH: Debug Cmd+C simulation clearing clipboard**
  - Status: Sometimes clears clipboard instead of copying selected text
  - Impact: Loses user's clipboard content unexpectedly  
  - Observed: Original content gets replaced with empty string
  - Next: Debug CGEvent timing and clipboard state management

## MEDIUM PRIORITY

### UX Improvements
- [ ] **MED: Make popup editor resizable**
  - Status: Currently fixed size with `.windowResizability(.contentSize)`
  - Impact: Limited editing experience for long text
  - Next: Change to `.contentMinSize` or custom resize behavior
  
- [ ] **MED: Improve window positioning calculation**
  - Status: Positioning logic seems correct but results are wrong
  - Impact: Inconsistent popup placement across different screens
  - Debug: Coordinate system differences, display bounds calculation

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

---

## IMPLEMENTATION NOTES

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

### Architecture & Core Setup
- [x] Modern `@Observable` state management implemented
- [x] KeyboardShortcuts framework integrated successfully  
- [x] PopStashApp structure modernized with proper lifecycle
- [x] AppDelegate integration completed and working
- [x] Basic clipboard capture and history functionality
- [x] Smart detection with Accessibility API implemented
- [x] Popup window state management (show/hide) working
- [x] Text editor popup functionality restored
- [ ] **FRAGILE: Window draggable and editable** 
  - Status: Currently working BUT very fragile - had to revert from `.plain` to `.hiddenTitleBar`
  - Problem: `.plain` = no buttons but kills drag/edit, `.hiddenTitleBar` = drag/edit works but shows buttons
  - Issue: No stable solution that gives us both button-free AND draggable/editable
  - Risk: Any window style change breaks either functionality or appearance
- [x] Option+C hotkey triggering and processing text
- [x] Clipboard content capture and popup display working