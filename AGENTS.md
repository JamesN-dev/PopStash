# PopStash Agent Guidelines

## Project Overview
PopStash is a macOS clipboard manager built with Swift/SwiftUI. It's an Xcode project targeting macOS 15.4+.

## Build Commands
- **Build**: Open `PopStash.xcodeproj` in Xcode and press `Cmd + B` or `Cmd + R` to build/run
- **Test**: No test suite currently exists in this project
- **Archive**: Use Xcode's Product → Archive for distribution builds

## Code Style Guidelines
- **Language**: Swift 5.0, SwiftUI for UI components
- **Imports**: Standard order - Foundation/AppKit first, then SwiftUI, then third-party
- **Naming**: Use camelCase for variables/functions, PascalCase for types/classes
- **Types**: Use explicit types where clarity is needed, rely on inference for simple cases
- **Error Handling**: Use do-catch blocks, print errors with descriptive messages
- **Comments**: Minimal inline comments, use `//` for single line, `/* */` for blocks
- **Architecture**: ObservableObject pattern for state management, @StateObject/@Published for reactive UI
- **File Organization**: One main type per file, group related functionality together

## Key Patterns
- Use `@StateObject` for view-owned objects, `@EnvironmentObject` for shared state
- Implement `Identifiable` for list items, use UUID for unique IDs
- Follow SwiftUI declarative patterns with computed properties for derived state
- Use `Codable` for data persistence with JSON encoding/decoding