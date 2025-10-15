# PopStash

A powerful clipboard manager for macOS that keeps your copy history organized and accessible.

## Features

### Core Functionality

- **Clipboard History** - Automatically saves everything you copy
- **Quick Access** - Global hotkey to instantly view your clipboard history
- **Smart Search** - Find any copied item with real-time search
- **Pin Important Items** - Keep frequently used content at the top

### Modern Interface

- **Glass Effect Design** - Beautiful translucent interface that fits macOS
- **Dual Panel Layout** - Main clipboard view with optional metadata sidebar
- **Keyboard Navigation** - Full keyboard support with arrow keys and shortcuts
- **Multi-Selection** - Select and manage multiple items at once

### Content Support

- **Text Snippets** - Copy and manage text of any length
- **Image Support** - Preview and manage copied images
- **Rich Metadata** - View source app, timestamps, and content details
- **Quick Preview** - See content without leaving the clipboard manager

### Productivity Features

- **Instant Copy** - Click any item to copy it back to clipboard
- **Keyboard Shortcuts** - Option+1-9 for quick access to recent items
- **PopEditor Integration** - Edit text items in a dedicated editor window
- **Smart Organization** - Pinned items stay at top, recent items below

### Customization

- **Accent Colors** - Choose from multiple color themes
- **Item Count Display** - Show/hide clipboard item counter
- **Configurable Shortcuts** - Customize global hotkeys
- **Privacy Controls** - Manage what gets saved to clipboard history

## Installation

1. Download the latest release from [Releases](https://github.com/JamesN-dev/PopStash/releases)
2. Drag PopStash.app to your Applications folder
3. Launch PopStash and grant necessary permissions
4. Use the global hotkey (default: Cmd+Shift+V) to access your clipboard

## Usage

### Basic Operations

- **Copy anything** - PopStash automatically saves it
- **Press Cmd+Shift+V** - Opens the clipboard manager
- **Click any item** - Copies it back to your clipboard
- **Search** - Type to filter your clipboard history
- **Pin items** - Click the pin icon to keep items at the top

### Keyboard Shortcuts

- `Cmd+Shift+V` - Open/close PopStash
- `Option+1-9` - Quick copy recent items
- `Arrow Keys` - Navigate clipboard items
- `Enter` - Copy selected item
- `Delete` - Remove selected item
- `Cmd+A` - Select all items
- `I` - Toggle metadata sidebar

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
