# PopStash CRUSH Development Guide

## Build Commands

```bash
# Build project with SPM dependencies
xcodebuild -project PopStash.xcodeproj -scheme PopStash -configuration Debug build

# Build for release
xcodebuild -project PopStash.xcodeproj -scheme PopStash -configuration Release build

# Clean build
xcodebuild -project PopStash.xcodeproj -scheme PopStash clean build
```

## Lint/Test Commands

```bash
# No specific linting configured
# No unit tests currently implemented
```

## Code Style Guidelines

### Import Ordering

1. System frameworks (Foundation, AppKit, SwiftUI, OSLog)
2. Third-party frameworks (KeyboardShortcuts)
3. Local imports

### Naming Conventions

- Variables/functions: camelCase
- Types: PascalCase
- Files: PascalCase with suffix matching type (e.g., View, Manager)
- Private members: Use `private` access control instead of underscores

### Error Handling

- Use do/catch for operations that can fail
- Log errors using unified logging (Logger)
- Fail gracefully with sensible defaults

### Comment Style

- Double slash (//) for inline comments
- Triple slash (///) for documentation comments
- MARK comments to organize code sections

### File Organization

- Views in Views/ directory with hierarchical subdirectories
- Models in Models/ directory
- Services in Services/ directory
- Extensions and protocols near their primary type usage
- Use MARK comments to separate logical sections

### Dependencies

- KeyboardShortcuts framework integrated via Swift Package Manager
- OSLog Logger used for all logging with subsystem/category organization

### Access Control

- Use `private` and `private(set)` for encapsulation instead of underscore prefixes
- Prefer `@Environment` and `@State` for SwiftUI property access control

## Navigation & Layout Pattern

- MenuBarExtra root uses a conditional `Group` to swap between `ClipboardHistoryView` and `PreferencesView` (no nested NavigationStack) for deterministic width management.
- Width rules: 320pt baseline, 600pt only when metadata sidebar is visible on history screen.
- Preferences always single-pane at 320pt with inline header + back button and footer.

## Glass / Material Usage

- Apply `.glassEffect()` once at root container per pane; child views avoid reapplication to prevent double rounding & translucency layering artifacts.
- Metadata sidebar toggling animates width; content stays mounted for performance (no expensive reconstruction).

## Clipboard List Performance / UX

- Disabled implicit row insertion animations on history updates to eliminate vertical push jitter.
- Slight positive top padding (2pt) avoids first row clipping under toolbar.
- Focus ring (accent stroke) indicates keyboard selection separate from hover highlight.
- Multi-selection: Shift+arrow expands, Shift+click range selects, Cmd+A selects all.

## Search Field Behavior

- While search is focused, selection sync is suppressed to prevent focus theft after several keystrokes (fixes “system beep” issue when typing).

## Preferences View

- Inline header provides back navigation via injected closure.
- No internal glass; inherits root glass for consistent corner mask.
- Content width hard constrained (320) to prevent expansion artifacts.

## History Insertion Logic

- New capture inserted at index 0 after dedupe (removes existing identical content before insertion) ensuring true LRU stack behavior.
- Internal copy flag prevents programmatic copies from generating duplicate insertion events during clipboard monitoring cycle.

## Future Enhancements (See TODO.md)

- Live editing sync for history items from popup/editor.
- Sticky PopEditor mode.
- Accessibility permission reliability improvements.
