# Coffee Break — Focus Timer for macOS

A minimal, polished focus timer that lives in your macOS menu bar. Built with Swift, SwiftUI, and AppKit.

## Install

1. Download **Coffee-Break.zip** from the [latest release](https://github.com/me1anius/pomodoro-macOS/releases/latest)
2. Unzip it
3. Drag **Coffee Break.app** to your Applications folder
4. Open it — the coffee cup icon will appear in your menu bar

> **Note:** On first launch, macOS may block the app. Go to **System Settings → Privacy & Security**, scroll down, and click **Open Anyway** to allow it.

Works on Apple Silicon and Intel Macs running **macOS 13.0+** (Ventura or later).

## Features

- **Menu bar native** — no Dock icon, no main window. Just a clean status item with live countdown
- **Coffee-themed UI** — warm brown colour scheme, circular progress ring, frosted glass background, spring animations
- **Global keyboard shortcuts** — customisable hotkeys for start/pause, skip, and reset
- **Configurable** — work/break durations, auto-start, sound toggles, all persisted across launches
- **Smart session flow** — automatic work → short break → work → ... → long break cycling
- **Session naming** — optionally name your focus sessions
- **Notifications** — macOS notifications + chime sound on session transitions
- **Light & Dark mode** — follows system appearance automatically

## Usage

- Click the ☕ in the menu bar to open the popover
- Press **Play** to start a 25-minute focus session
- The menu bar shows a live countdown: `☕ 18:32`
- During breaks, the icon switches to a 🌙 moon
- When a session ends, you'll hear a chime and see a notification
- Click the **gear icon** to adjust durations, sounds, and keyboard shortcuts
- Right-click the menu bar icon to quit

## Customisation

All settings are persisted via `UserDefaults` and survive app restarts:

| Setting | Default |
|---------|---------|
| Focus duration | 25 min |
| Short break | 5 min |
| Long break | 15 min |
| Sessions before long break | 4 |
| Auto-start breaks | Off |
| Auto-start focus sessions | Off |
| Sound on session end | On |
| Tick sound | Off |
| Show timer in menu bar | On |

## Build from Source

If you'd prefer to build it yourself, no Xcode required — just the Command Line Tools:

```bash
xcode-select --install   # if not already installed
cd pomodoro-macOS
chmod +x build.sh
./build.sh
cp -r "build/Coffee Break.app" /Applications/
```

## Project Structure

```
Pomodoro/
├── Sources/
│   ├── PomodoroApp.swift          # @main entry point
│   ├── AppDelegate.swift          # Sets up NSStatusItem + NSPopover
│   ├── MenuBarController.swift    # Manages menu bar item and popover
│   ├── HotkeyManager.swift        # Global keyboard shortcuts (Carbon API)
│   ├── TimerViewModel.swift       # Core timer logic (ObservableObject)
│   ├── TimerView.swift            # Main popover UI (progress ring + controls)
│   ├── SettingsView.swift         # Inline settings panel
│   ├── ProgressRing.swift         # Circular progress component
│   ├── NotificationManager.swift  # macOS notifications + sound
│   └── Constants.swift            # Defaults, colours, sizing
├── Resources/                     # Menu bar icons (coffee + moon)
├── Assets.xcassets/               # App icon asset catalog
├── Info.plist                     # LSUIElement = YES (no Dock icon)
└── Pomodoro.entitlements          # App sandbox
```
