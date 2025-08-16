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

## 🚀 Quick Start

### Step 1: Get AeroSwitch

#### Option A: Download Pre-built Binary (Recommended)

1. **Download the latest release:**
   - Go to [Releases](https://github.com/yourusername/aeroswitch/releases)
   - Download `aeroswitch-1.0.0-macos.tar.gz`

2. **Extract and install:**
   ```bash
   tar -xzf aeroswitch-1.0.0-macos.tar.gz
   sudo mv aeroswitch /usr/local/bin/
   chmod +x /usr/local/bin/aeroswitch
   ```

#### Option B: Build from Source

```bash
git clone https://github.com/yourusername/aeroswitch.git
cd aeroswitch
make release
sudo make install
```

### Step 2: Configure AeroSpace

Add AeroSwitch to your AeroSpace configuration (`~/.aerospace.toml`):

```toml
# Start AeroSwitch as a background service
[[on-window-detected]]
if.app-id = 'com.apple.loginwindow'
run = '/usr/local/bin/aeroswitch --background'

# Bind a hotkey to summon the window switcher
[mode.main.binding]
cmd-tab = 'exec-and-forget /usr/local/bin/aeroswitch --activate'
```

### Step 3: Start Using

1. **Restart AeroSpace** to load the new configuration
2. **Press Cmd+Tab** (or your chosen hotkey) to open the window switcher
3. **Type to search** for windows by app name or title
4. **Press Enter** or click to switch to the selected window

That's it! 🎉

## ⚙️ Configuration Examples

### Alternative AeroSpace Setups

#### Don't Override Cmd+Tab
If you prefer to keep macOS native Cmd+Tab:
```toml
# Use Alt+Space or Cmd+Shift+Tab instead
[mode.main.binding]
alt-space = 'exec-and-forget /usr/local/bin/aeroswitch --activate'
# or
cmd-shift-tab = 'exec-and-forget /usr/local/bin/aeroswitch --activate'
```

#### Summon Mode (Bring Windows to Current Workspace)
```toml
# Start with summon mode
[[on-window-detected]]
if.app-id = 'com.apple.loginwindow'
run = '/usr/local/bin/aeroswitch --background --summon'

# All windows will be brought to your current workspace
[mode.main.binding]
cmd-tab = 'exec-and-forget /usr/local/bin/aeroswitch --activate'
```

#### Both Focus and Summon Modes
```toml
# Default background service
[[on-window-detected]]
if.app-id = 'com.apple.loginwindow'
run = '/usr/local/bin/aeroswitch --background'

[mode.main.binding]
# Focus mode: go to window's workspace
cmd-tab = 'exec-and-forget /usr/local/bin/aeroswitch --activate'
# Summon mode: bring window here
cmd-shift-tab = 'exec-and-forget /usr/local/bin/aeroswitch --activate --summon'
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

## 🔧 Advanced Installation

### Homebrew (For Distribution)

If you're planning to distribute AeroSwitch or want automatic updates:

```bash
# Once the tap is set up
brew tap yourusername/aeroswitch
brew install aeroswitch
```

See [HOMEBREW_TAP.md](HOMEBREW_TAP.md) for detailed setup instructions.

### Manual Build Options

```bash
# Using Makefile
make release        # Build release binary
make install        # Install to /usr/local/bin (requires sudo)
make archive        # Create release archive

# Using Swift directly  
swift build -c release
sudo cp .build/release/aeroswitch /usr/local/bin/
```

## 💡 Tips

### Workspace Strategies

AeroSwitch supports two workspace switching strategies:

1. **Focus Mode** (default): Switches to the target workspace, then focuses the window
2. **Summon Mode**: Brings the window to the current workspace

### AeroSpace Integration

AeroSwitch automatically detects your AeroSpace installation in common locations:
- `/opt/homebrew/bin/aerospace`
- `/usr/local/bin/aerospace`  
- `/usr/bin/aerospace`

### Troubleshooting

**AeroSwitch won't start:**
- Check that the binary is executable: `chmod +x /usr/local/bin/aeroswitch`
- Verify AeroSpace is running: `ps aux | grep aerospace`

**Window switcher doesn't appear:**
- Make sure the background process is running: `ps aux | grep aeroswitch`
- Check AeroSpace logs for any errors

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

This project is licensed under the GPL v3 License - see the [LICENSE](LICENSE) file for details.

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