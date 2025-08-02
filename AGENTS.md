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

## Forbidden Patterns
❌ `@StateObject/@ObservedObject` → Use `@State` + `@Observable`
❌ `@EnvironmentObject` → Use `@Environment(MyType.self)`
❌ `NSWindow/NSViewRepresentable` → Use SwiftUI `Window(id:)`
❌ Background clipboard monitoring → User-initiated only

## Privacy Requirements
- Option+C hotkey for clipboard access (KeyboardShortcuts framework)
- NO background clipboard polling/monitoring
- App Store compliance - no accessibility APIs
