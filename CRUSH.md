# PopStash - CRUSH Development Guidelines

## Project Overview
PopStash is a next-generation macOS clipboard manager built with the latest Swift and SwiftUI frameworks targeting macOS 15.4+. It's designed to be ready for future macOS releases with a focus on App Store compliance, privacy, and modern Swift patterns.

## Build Commands
- **Build**: Use Xcode Product → Build or Cmd+B
- **Run**: Use Xcode Product → Run or Cmd+R
- **Test**: No test suite currently exists in this project
- **Archive**: Use Xcode Product → Archive for distribution builds

## Core Features
- Text-only clipboard history with de-duplication
- Option + C universal clipboard hotkey (user-initiated access only)
- Notification-style editable popup buffer
- Menu bar app (dockless) with native macOS feel
- Modern "Liquid Glass" UI with ultraThickMaterial

## Code Style Guidelines

### Language & Frameworks
- Latest Swift with @Observable macro (NO ObservableObject)
- Modern SwiftUI for all UI components
- Pure SwiftUI Window management (NO NSWindow)
- Modern concurrency (async/await) when needed

### Imports Order
1. Foundation/AppKit
2. SwiftUI
3. Third-party frameworks

### Naming Conventions
- camelCase for variables and functions
- PascalCase for types and classes
- Descriptive, meaningful names

### Types & Declaration
- Use explicit types where clarity is needed
- Rely on type inference for simple cases
- Prefer structs and value types over classes

### Error Handling
- Use do-catch blocks with descriptive error messages
- Print errors with context: print("Error in \(function): \(error)")

### Comments
- Minimal inline comments focusing on why rather than what
- Use // for single-line comments
- Use /* */ for multi-line comments

### File Organization
- One main type per file
- Group related functionality together

## Architecture Patterns

### State Management
- @Observable for model objects only
- @State with @Observable classes in views
- @Environment(MyType.self) for shared state
- NO @StateObject, @ObservedObject, or @EnvironmentObject

### View Patterns
- Use .onChange, .task instead of onReceive
- SwiftUI Window(id:) for window management
- .menuBarExtraStyle(.window) for menu bar apps
- Identifiable with UUID for list items

### Hotkey System
- RegisterEventHotKey (Carbon) for Option + C
- User-initiated clipboard access only
- No polling, timers, or background monitoring

### Data Persistence
- Codable with JSON encoding/decoding
- ~/Library/Application Support for storage
- NSPasteboard.detectFormats() before reading content

## Forbidden Legacy Patterns
❌ ObservableObject + @Published
❌ @StateObject / @ObservedObject
❌ @EnvironmentObject
❌ onReceive
❌ NSWindow / NSViewRepresentable
❌ NotificationCenter
❌ Timer-based clipboard polling
❌ Cmd + C detection

## Privacy & Compliance Requirements
✅ Option + C global hotkey only (user-initiated)
✅ NSPasteboard.detectFormats() before reading
✅ No background clipboard monitoring
✅ No Cmd + C interception
✅ App Store compliant - no accessibility APIs
✅ macOS 15.4+ pasteboard privacy compliance