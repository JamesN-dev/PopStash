# PopStash Agent Guidelines

## Project Overview

PopStash is a next-generation macOS clipboard manager built with the latest Swift/SwiftUI technologies. It's an Xcode 16+ project targeting macOS 15.4+ (Sequoia), and is designed to be ready for Xcode 17/“26” and macOS 16+ for maximum future-proofing. The focus is on App Store compliance, privacy, and modern Swift patterns.

## Build Commands

- **Build**: Dont build without explicit instruction. Let user know when ready and they will build and test the app.
- **Test**: No test suite currently exists in this project
- **Archive**: Use Xcode's Product → Archive for distribution builds

## Code Style Guidelines - MODERN SwiftUI ONLY

- **Language**: Swift 6+, SwiftUI 5+ for UI components (ready for SwiftUI 6)
- **Target**: macOS 15.4+ (no legacy iOS patterns)
- **Imports**: Standard order - Foundation/AppKit first, then SwiftUI, then third-party
- **Naming**: Use camelCase for variables/functions, PascalCase for types/classes
- **Types**: Use explicit types where clarity is needed, rely on inference for simple cases
- **Error Handling**: Use do-catch blocks, print errors with descriptive messages
- **Comments**: Minimal inline comments, use `//` for single line, `/* */` for blocks
- **File Organization**: One main type per file, group related functionality together

## Architecture - NO LEGACY PATTERNS

- **State Management**: `@Observable` macro ONLY (Swift 5.9+)
- **Shared State**: `@Environment(MyType.self)` + `.environment(value)`
- **View State**: `@State` with `@Observable` classes
- **Window Management**: Pure SwiftUI `Window(id:)`, `MenuBarExtra`
- **Animations**: `.transaction`, `.onAppear`, `.onDisappear`
- **Material Design**: `.ultraThickMaterial`, `.windowStyle(.hiddenTitle)`

## Key Patterns - Modern SwiftUI 5+

- Use `@Observable` for all state objects - NO `ObservableObject`
- Use `@State` + `@Observable` instead of `@StateObject`
- Use `@Environment(MyType.self)` instead of `@EnvironmentObject`
- Use `.onChange`, `.task` instead of `onReceive`
- Use SwiftUI `Window(id:)` instead of `NSWindow`
- Use `.menuBarExtraStyle(.window)` for modern menu bar style
- Implement `Identifiable` for list items, use UUID for unique IDs
- Follow SwiftUI declarative patterns with computed properties
- Use `Codable` for data persistence with JSON encoding/decoding

## FORBIDDEN Legacy Patterns

❌ `@StateObject` / `@ObservedObject` → Use `@State` + `@Observable`
❌ `@EnvironmentObject` → Use `@Environment(MyType.self)`
❌ `ObservableObject` + `@Published` → Use `@Observable` macro
❌ `onReceive` → Use `.onChange`, `.task`
❌ `NSWindow` / `NSViewRepresentable` → Use SwiftUI `Window(id:)`
❌ `NotificationCenter` → Use `@Binding`, `@Environment`
❌ Timer-based clipboard polling → Use user-initiated access only

## Privacy & Compliance Requirements

- ✅ Use `Option + C` global hotkey for user-initiated clipboard access
- ✅ Use `NSPasteboard.detectFormats()` before reading content
- ✅ NO background clipboard monitoring or polling
- ✅ NO `Cmd + C` detection or interception
- ✅ App Store compliant - no accessibility APIs for spying
- ✅ macOS 15.4+ pasteboard privacy compliance

## Technical Stack

| Component   | Technology               | Requirement                   |
| ----------- | ------------------------ | ----------------------------- |
| State       | `@Observable`            | Swift 5.9+ only               |
| UI          | SwiftUI 5+               | No AppKit views               |
| Hotkeys     | `RegisterEventHotKey`    | App Store safe                |
| Clipboard   | `NSPasteboard` on-demand | Privacy compliant             |
| Windows     | `Window(id:)`            | Pure SwiftUI                  |
| Persistence | `Codable` + JSON         | ~/Library/Application Support |

## Development Philosophy

We are building for the future of SwiftUI, not porting legacy code:

- Zero compromises on modern Swift syntax
- Future-proof for macOS 16+ and Xcode 17+ (Xcode "26" ready)
- Native macOS experience, not adapted iOS patterns
- App Store ready from day one
- Privacy-first design

## API Reference & Documentation

- Agents should always fetch Context7 SwiftUI docs for the latest API references and patterns.
- Ensure all code and recommendations align with the most current SwiftUI and Swift releases.
