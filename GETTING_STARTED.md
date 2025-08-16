# Getting Started with AeroSwitch

**The fastest window switcher for AeroSpace users**

## ⚡ 3-Minute Setup

### 1. Install with Homebrew (30 seconds)

```bash
# Add the tap and install
brew tap darksworm/aerospace
brew install aeroswitch

# Test it works
aeroswitch --version
```

**Alternative: Manual Install**
```bash
# Download latest release
curl -L https://github.com/darksworm/aeroswitch/releases/latest/download/aeroswitch-1.0.0-macos.tar.gz -o aeroswitch.tar.gz

# Extract and install
tar -xzf aeroswitch.tar.gz
sudo mv aeroswitch /usr/local/bin/
chmod +x /usr/local/bin/aeroswitch
```

### 2. Configure AeroSpace (1 minute)

Add these lines to your `~/.aerospace.toml`:

```toml
# Auto-start AeroSwitch with AeroSpace
[[on-window-detected]]
if.app-id = 'com.apple.loginwindow'
run = '/opt/homebrew/bin/aeroswitch --background'

# Bind Cmd+Tab to open window switcher  
[mode.main.binding]
cmd-tab = 'exec-and-forget /opt/homebrew/bin/aeroswitch --activate'
```

### 3. Restart AeroSpace (10 seconds)

```bash
# Restart AeroSpace to load new config
aerospace --restart
```

## 🎉 You're Done!

Press **Cmd+Tab** to open the window switcher, then:
- **Type** to search for apps or window titles
- **Arrow keys** to navigate
- **Enter** to switch to selected window
- **Esc** to cancel

## 🔧 Alternative Hotkeys

Don't want to override Cmd+Tab? Use these instead:

```toml
# Option 1: Alt+Space
[mode.main.binding]
alt-space = 'exec-and-forget /opt/homebrew/bin/aeroswitch --activate'

# Option 2: Cmd+Shift+Tab  
[mode.main.binding]
cmd-shift-tab = 'exec-and-forget /opt/homebrew/bin/aeroswitch --activate'
```

## 🚀 Pro Tips

**Summon Mode**: Bring windows to your current workspace instead of switching to theirs:
```toml
[[on-window-detected]]
if.app-id = 'com.apple.loginwindow'
run = '/opt/homebrew/bin/aeroswitch --background --summon'
```

**Both Modes**: Have separate hotkeys for each strategy:
```toml
[mode.main.binding]
cmd-tab = 'exec-and-forget /opt/homebrew/bin/aeroswitch --activate'        # Go to window
cmd-shift-tab = 'exec-and-forget /opt/homebrew/bin/aeroswitch --activate --summon'  # Bring window here
```

## ❓ Problems?

**Window switcher doesn't appear?**
```bash
# Check if AeroSwitch is running
ps aux | grep aeroswitch

# If not, start it manually
aeroswitch --background
```

**AeroSpace doesn't start AeroSwitch?**
- Make sure you restarted AeroSpace after config changes
- Check the file path in your config matches: `/opt/homebrew/bin/aeroswitch` (or `/usr/local/bin/aeroswitch` if manually installed)

**Want to try without Cmd+Tab override?**
- Test with: `aeroswitch --activate` in terminal first
- Then bind to a different key in your AeroSpace config

---

**Need more help?** Check the full [README.md](README.md) or create an [issue](https://github.com/darksworm/aeroswitch/issues).