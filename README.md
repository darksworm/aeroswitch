# AeroSwitch

<p align="center">
  <img src="Assets.xcassets/AppIcon.appiconset/128.png" alt="AeroSwitch Icon" width="128" height="128">
</p>

**A fast and lightweight window switcher for AeroSpace users**

AeroSwitch is designed for users who struggle with switching workspaces by number. Instead of memorizing workspace numbers, simply search for your applications by name and switch directly to any window across all workspaces.

## ✨ Features

- **🔍 Smart Search**: Search windows by application name or window title
- **🚀 Lightning Fast**: Instant fuzzy search with intelligent scoring
- **🎨 Beautiful UI**: Translucent design with rounded corners and app icons
- **⌨️ Keyboard Driven**: Navigate entirely with keyboard shortcuts
- **🖱️ Mouse Support**: Click to select windows when preferred
- **📱 System Tray**: Unobtrusive system tray integration
- **🔄 Auto-Hide**: Automatically closes when losing focus
- **🎯 Two Strategies**: Choose between workspace focus or summon modes

## 🖼️ Screenshot

The window switcher displays a clean, searchable list of all windows across workspaces with:
- Application icons for easy visual identification
- App name and window title
- Current workspace indicator
- Translucent background that adapts to your desktop

## 🚀 Getting Started

### Prerequisites

- macOS 13.0 or later
- [AeroSpace](https://github.com/nikitabobko/AeroSpace) window manager
- Swift 6.1 or later (for building from source)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/aeroswitch.git
   cd aeroswitch
   ```

2. **Build the application:**
   ```bash
   swift build -c release
   ```

3. **Run AeroSwitch:**
   ```bash
   # Start as background process
   ./.build/release/aeroswitch --background
   
   # Or activate existing instance
   ./.build/release/aeroswitch --activate
   ```

### Usage

#### Command Line Options

```bash
aeroswitch [OPTIONS]

Options:
  --background    Start as background helper process
  --activate      Activate existing helper process  
  --summon        Use summon-workspace instead of workspace switching
  --help, -h      Show help message

Default behavior:
  If no flags are provided, will activate existing instance or start background process.
```

#### Keyboard Shortcuts

- **Search**: Start typing to filter windows
- **Navigate**: Use `↑` and `↓` arrow keys to select windows
- **Activate**: Press `Enter` to switch to selected window
- **Cancel**: Press `Esc` to close the switcher

#### System Tray

Right-click the system tray icon for options:
- **Show Window Switcher**: Open the window switcher manually
- **Quit AeroSwitch**: Exit the application

## ⚙️ Configuration

### Workspace Strategies

AeroSwitch supports two workspace switching strategies:

1. **Focus Mode** (default): Switches to the target workspace, then focuses the window
2. **Summon Mode**: Brings the window to the current workspace

Use the `--summon` flag to enable summon mode:

```bash
aeroswitch --background --summon
```

### Integration with AeroSpace

AeroSwitch automatically detects your AeroSpace installation in common locations:
- `/opt/homebrew/bin/aerospace`
- `/usr/local/bin/aerospace`
- `/usr/bin/aerospace`

## 🔧 Development

### Building from Source

```bash
# Debug build
swift build

# Release build
swift build -c release

# Run tests (when available)
swift test
```

### Project Structure

```
aeroswitch/
├── Sources/
│   └── main.swift          # Main application code
├── Assets.xcassets/        # App icons and assets
│   └── AppIcon.appiconset/
├── Package.swift           # Swift Package Manager configuration
└── README.md              # This file
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development Guidelines

- Follow Swift conventions and best practices
- Test changes thoroughly with AeroSpace
- Update documentation for new features
- Use semantic commit messages

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [AeroSpace](https://github.com/nikitabobko/AeroSpace) - The excellent tiling window manager that inspired this tool
- Swift and SwiftUI communities for excellent documentation and examples

## 📞 Support

If you encounter issues or have questions:

1. Check the [Issues](https://github.com/your-username/aeroswitch/issues) page
2. Create a new issue with detailed information about your problem
3. Include your macOS version, AeroSpace version, and steps to reproduce

---

**Made with ❤️ for the AeroSpace community**