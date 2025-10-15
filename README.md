# PopStash

> **⚠️ Pre-release Software**: PopStash is currently in active development and not ready for production use. Features may be incomplete, unstable, or subject to change.

A powerful clipboard manager for macOS that keeps your copy history organized and accessible.

## Features

- **Clipboard History** - Automatically saves everything you copy
- **Quick Access** - Global hotkey to instantly view your clipboard history  
- **Smart Search** - Find any copied item with real-time search
- **Pin Important Items** - Keep frequently used content at the top
- **Glass Effect Design** - Beautiful translucent interface that fits macOS
- **Keyboard Navigation** - Full keyboard support with arrow keys and shortcuts
- **Text & Image Support** - Preview and manage copied text and images
- **PopEditor Integration** - Edit text items in a dedicated editor window

## Installation

**Pre-release**: Currently in development. To try it out:

1. Clone this repository
2. Open PopStash.xcodeproj in Xcode
3. Build and run the project
4. Grant necessary permissions when prompted
5. Use Option+C to capture clipboard content

## Usage

### Basic Operations

- **Copy anything** - PopStash automatically saves it
- **Press Cmd+Shift+V** - Opens the clipboard manager
- **Click any item** - Copies it back to your clipboard
- **Search** - Type to filter your clipboard history
- **Pin items** - Click the pin icon to keep items at the top

### Keyboard Shortcuts

- `Option+C` - Capture clipboard content
- `Arrow Keys` - Navigate clipboard items
- `Enter` - Copy selected item
- `Delete` - Remove selected item
- `Cmd+A` - Select all items

### Advanced Features

- **Multi-select** - Hold Shift and click to select ranges
- **Context menus** - Right-click items for more options
- **Edit text** - Option+click text items to edit in PopEditor
- **Metadata view** - Toggle sidebar to see item details and actions

## Requirements

- macOS 13.0 or later
- Accessibility permissions (for global hotkeys)
- Approximately 10MB disk space

## Privacy

PopStash stores clipboard data locally on your Mac. No data is sent to external servers. You can clear your clipboard history at any time from the app's footer.

## Development

PopStash is built with:

- **SwiftUI** - Modern declarative UI framework
- **AppKit** - Native macOS integration
- **Combine** - Reactive programming for data flow

### Building from Source

```bash
git clone https://github.com/JamesN-dev/PopStash.git
cd PopStash
open PopStash.xcodeproj
```

Build and run in Xcode 15.0 or later.

## Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

## License

PopStash is available under the MIT License. See LICENSE for details.

## Support

If you encounter any issues or have questions:

- Check the [Issues](https://github.com/JamesN-dev/PopStash/issues) page
- Create a new issue with details about your problem
- Include your macOS version and PopStash version

---
