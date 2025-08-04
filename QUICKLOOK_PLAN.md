# PopStash Quick Look Implementation Plan

## Overview
Transform PopStash clipboard history into a native macOS Finder-style experience with keyboard navigation and Quick Look preview system.

## Core User Experience

### Current Flow:
1. Click MenuBar → Clipboard list appears
2. Click item → Copies to clipboard
3. Right-click → Context menu for pin/delete

### New Flow:
1. Click MenuBar → Clipboard list appears (Finder-style)
2. Arrow keys navigate items
3. **Space key → Full Quick Look overlay** (like Finder)
4. **Enter key → Copy to clipboard**
5. **Option+click → PopEditor for editing**
6. Click item → Show metadata sidebar

## 1. Quick Look Overlay (HIGH PRIORITY)

### Visual Design - Pixel Perfect Match
- **Fullscreen dark overlay** with system blur
- **Header bar layout**: `[X] [⤢] PopStash Item #47        [Share] [Open with PopEditor]`
- **Left side buttons**:
  - Circle X (close) 
  - Circle expand/fullscreen button
  - Title: "PopStash Item #N"
- **Right side buttons**:
  - Share button (Phase 3 - export .txt)
  - "Open with PopEditor" button
- **Content area**: 
  - Dark/light mode adaptive
  - Rounded corners like native Quick Look
  - Plain text display (markdown support later)
  - Full content scrollable

### Keyboard Behavior
- **Space key**: Trigger Quick Look from selected item
- **ESC key**: Close Quick Look overlay
- **Arrow keys**: Navigate between items while in Quick Look
- **Enter in Quick Look**: Copy item and close
- **Option+Enter**: Open PopEditor and close Quick Look

### Implementation Notes
- Custom SwiftUI `.overlay(.fullscreen)`
- Match native Quick Look visual styling exactly
- System color scheme adaptation
- Proper focus management and keyboard handling

## 2. Keyboard Navigation (HIGH PRIORITY)

### List Navigation
- **Up/Down arrows**: Navigate clipboard items
- **Home/End**: Jump to first/last item
- **Page Up/Down**: Scroll by page
- **Tab**: Move focus to toolbar buttons
- **Escape**: Close MenuBar dropdown

### Selection State
- Visual selection indicator (blue highlight)
- Maintain selection when switching between list/Quick Look
- Auto-select first item when opening MenuBar
- Selection survives search filtering

### Integration with Quick Look
- Selected item determines Quick Look content
- Arrow keys work inside Quick Look to switch items
- Seamless transition between list navigation and preview

## 3. Finder-Style Metadata Sidebar (MEDIUM PRIORITY)

### Panel Layout
Similar to Finder's info panel:
```
┌─────────────────────────────┐
│ PopStash Clipboard Item     │
│ Text Content - 142 chars    │
│                             │
│ Information                 │
│ Created    Today, 6:51 PM   │
│ Modified   Today, 6:51 PM   │
│ Source App TextEdit         │
│                             │
│ [Pin/Unpin Button]          │
│                             │
│ ••• More...                 │
└─────────────────────────────┘
```

### Content Display
- **Item type**: "Text Content - N characters" or "Image - WxH"
- **Timestamps**: Created/Modified with relative dates
- **Source app**: Actual app name (fix "Unknown Application")
- **Content preview**: First few lines of text
- **Metadata**: Character count, word count, line count

### Toggle Behavior
- Hidden by default (single column list)
- Sidebar button in toolbar to show/hide
- Smooth slide-out animation
- Remember state in preferences

## 4. Clipboard List Polish (LOW PRIORITY)

### Visual Improvements
- **Divider lines**: Subtle separators between items
- **Reduced padding**: Less left padding for tighter layout
- **Material background**: Change to `.regularMaterial`
- **Finder-like spacing**: Match system list view spacing
- **Selection highlighting**: Blue selection like Finder

### Item Layout Changes
- **Single line**: Remove two-line layout, use single line with truncation
- **Icon consistency**: Smaller, consistent document icons
- **Pin indicator**: Subtle pin icon positioning
- **Keyboard shortcuts**: Show ⌥1-9 hints more subtly

## 5. PopEditor Integration

### Trigger Methods
- **Option+click** any clipboard item → PopEditor
- **"Open with PopEditor"** button in Quick Look → PopEditor
- **Option+Enter** while item selected → PopEditor

### PopEditor Enhancements
- **Blue drag outline**: Restore 1pt responsive drag outline
- **Content sync**: Live update clipboard history while typing
- **Window management**: Proper positioning after drag operations

## 6. Technical Implementation

### File Structure
```
Views/
├── QuickLook/
│   ├── QuickLookOverlay.swift      # Fullscreen overlay
│   ├── QuickLookHeader.swift       # Header with buttons
│   └── QuickLookContent.swift      # Content display
├── MenuBar/
│   ├── ClipboardHistoryView.swift  # Main list (updated)
│   ├── ClipboardRowView.swift      # Individual items (polished)
│   └── MetadataSidebar.swift       # Finder-style info panel
```

### State Management
- `@State private var selectedItemId: UUID?`
- `@State private var showingQuickLook: Bool = false`
- `@State private var showingSidebar: Bool = false`
- Keyboard event handling with `.onKeyPress`

### Animation System
- Quick Look: Fade in/out with scale effect
- Sidebar: Slide out from right with smooth spring
- List selection: Smooth highlight transitions

## 7. Future Phases

### Phase 2: Enhanced Features
- Markdown syntax highlighting in Quick Look
- Rich text preview for formatted content
- Image support in Quick Look overlay
- Copy formatting options

### Phase 3: Sharing & Export
- Share button implementation
- Export to .txt, .md files
- Cloud sharing integration
- Print support from Quick Look

### Phase 4: Advanced Navigation
- Search within Quick Look content
- Tags and categories
- Smart collections (Recent, Pinned, From App)
- Duplicate detection and merging

## Success Criteria

### User Experience Goals
1. **Feels completely native** - indistinguishable from Finder Quick Look
2. **Keyboard-first workflow** - power users can navigate entirely with keys
3. **Discoverable for casual users** - clicking and space bar work intuitively
4. **Fast and responsive** - no lag in navigation or Quick Look display

### Technical Goals
1. **Pixel-perfect native styling** - matches system appearance exactly
2. **Proper accessibility support** - VoiceOver and keyboard navigation
3. **Performance optimized** - smooth 60fps animations
4. **Memory efficient** - handles large clipboard histories

This plan transforms PopStash from a simple clipboard manager into a powerful, native-feeling macOS productivity tool that leverages familiar Finder patterns.