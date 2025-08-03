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