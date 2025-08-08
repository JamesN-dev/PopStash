# PopStash Agent Guidelines

## Build Commands

- **Build**: Use Xcode only - notify user when ready for them to build/test
- **Test**: No test suite exists in this project
- **Archive**: Use Xcode Product → Archive for distribution

## Code Style - Modern SwiftUI Only

- **Language**: Swift 6+, SwiftUI 5+, macOS 15.4+ target
- **Imports**: Foundation/AppKit first, SwiftUI, then third-party (KeyboardShortcuts, OSLog)
- **Naming**: camelCase variables/functions, PascalCase types
- **Comments**: Minimal - use `//` single line, `/* */` blocks
- **Error Handling**: do-catch blocks, `print()` for errors
- **File Organization**: One main type per file, group with MARK comments

## Required Architecture

- **State**: `@Observable` macro ONLY - NO ObservableObject
- **Environment**: `@Environment(MyType.self)` + `.environment(value)`
- **Views**: `@State` with `@Observable` classes
- **Windows**: Pure SwiftUI `MenuBarExtra`, `Window(id:)`
- **Materials**: `.ultraThickMaterial`, `.regularMaterial`
- **Persistence**: `Codable` + JSON to ~/Library/Application Support
- **Navigation (Current Pattern)**: MenuBarExtra root swaps between history and preferences with a conditional `Group { if ... }` (not a nested NavigationStack) for precise width control (600 w/ sidebar, 320 single-pane).

## UI Composition Patterns

- **Glass Effect**: Apply `.glassEffect()` ONCE at the root container per pane; child views should not re-apply to avoid double clipping or bleed-through.
- **Preferences**: Always fixed at 320pt width; includes inline header (chevron + title) and footer. Back action injected via closure.
- **Clipboard List**: Custom focus ring (accent stroke) for keyboard-focused row; hover state uses lighter material & subtle highlight.
- **Top Row Spacing**: Avoid negative padding that causes clipping; slight positive padding (2pt) for breathing room.

## Forbidden Patterns

❌ `@StateObject/@ObservedObject` → Use `@State` + `@Observable`
❌ `@EnvironmentObject` → Use `@Environment(MyType.self)`
❌ `NSWindow/NSViewRepresentable` → Use SwiftUI `Window(id:)`
❌ Background clipboard monitoring → User-initiated only (internal timer only checks when triggered by user hotkeys logic; no passive capture)

## Privacy Requirements

- Option+C hotkey for clipboard access (KeyboardShortcuts framework)
- NO background clipboard polling/monitoring
- App Store compliance - no unapproved accessibility scraping (AX APIs only after explicit user permission prompt)

## Recent Implementation Notes

- Selection focus logic decoupled from hover; syncing suppressed while search field focused to prevent typing lockout.
- History insertion disables implicit animation to keep new item flush at top with no visual push-down artifact.
- Sidebar metadata panel is persistent; visibility toggled with width animation (320 → 600) instead of reconstructing view.
