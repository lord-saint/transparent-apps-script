# Transparent Apps Script

An AutoHotkey script that automatically makes specified applications transparent and provides hotkeys to control transparency levels dynamically.

## Features

✅ **Auto-Transparency** - Automatically makes Brave, VLC, and Notepad transparent when launched  
✅ **Toggle On/Off** - Use Ctrl+Shift+Right Click to enable/disable auto-transparency  
✅ **Increase Transparency** - Use Ctrl+Shift+Plus to make windows more transparent  
✅ **Decrease Transparency** - Use Ctrl+Shift+Minus to make windows more opaque  
✅ **Easy to Customize** - Add or remove apps with simple code modifications  

## Requirements

- **Windows OS** (Windows 7 or later)
- **AutoHotkey v2** - Download from [https://www.autohotkey.com/](https://www.autohotkey.com/)

## Installation

1. Download and install **AutoHotkey v2** from the official website
2. Download `transparent-apps.ahk` from this repository
3. Run the script by double-clicking the `.ahk` file
4. The script will run in the background

## Usage

### Hotkeys

| Hotkey | Action |
|--------|--------|
| `Ctrl+Shift+Right Click` | Toggle auto-transparency on/off |
| `Ctrl+Shift+Plus (Numpad)` | Increase transparency (make more see-through) |
| `Ctrl+Shift+Minus (Numpad)` | Decrease transparency (make more opaque) |

### Supported Apps (Default)

- **Brave Browser** (`brave.exe`)
- **VLC Media Player** (`vlc.exe`)
- **Notepad** (`notepad.exe`)

## How It Works

1. The script checks every 1 second if any of the supported apps are open
2. When enabled, it automatically applies a semi-transparent effect (transparency level 220)
3. You can toggle this auto-check on/off or adjust transparency levels manually
4. When disabled, windows return to full opacity (255)

## Adding More Apps

To add more applications to the script, follow these steps:

1. Find the `.exe` filename of the app you want to add (e.g., `spotify.exe`, `discord.exe`)
2. Open `transparent-apps.ahk` in a text editor
3. In the `CheckApps()` function, add a new line:
```autohotkey
if WinExist("ahk_exe spotify.exe")
    WinSetTransparent(currentTransparency, "ahk_exe spotify.exe")
```

4. In the `^+RButton::` hotkey section, add the app to the condition:
```autohotkey
if (procName = "brave.exe" or procName = "vlc.exe" or procName = "notepad.exe" or procName = "spotify.exe")
```

## Transparency Values

- `0` = Fully transparent (invisible)
- `127` = Semi-transparent (middle point)
- `220` = Default transparency (slightly see-through)
- `255` = Fully opaque (normal/no transparency)

## Troubleshooting

**Script won't run:**
- Make sure AutoHotkey v2 is installed
- Try right-clicking the script and selecting "Run with AutoHotkey v2"

**Hotkeys not working:**
- Check if AutoHotkey is running in the background (look in system tray)
- Restart the script
- Make sure you're pressing the correct key combinations

**Transparency not applying:**
- Some apps may have restrictions that prevent transparency effects
- Try with a different supported app first

## Hotkey Modifiers Reference

- `^` = Ctrl
- `+` = Shift
- `!` = Alt
- `#` = Win key

## License

Free to use, modify, and distribute.

## Author

Created with ❤️ for better window management

## Support

If you encounter any issues or want to request features, feel free to open an issue in this repository.
