# Pomodoro Timer — macOS Menu Bar App

A minimal, polished Pomodoro timer that lives in your macOS menu bar. Built with Swift, SwiftUI, and AppKit.

## Features

- **Menu bar native** — no Dock icon, no main window. Just a clean status item with live countdown
- **Beautiful popover UI** — circular progress ring with gradient stroke, frosted glass background, spring animations
- **Configurable** — work/break durations, auto-start, sound toggles, all persisted across launches
- **Smart session flow** — automatic work → short break → work → ... → long break cycling
- **Notifications** — macOS notifications + chime sound on session transitions
- **Light & Dark mode** — follows system appearance automatically

## Requirements

- **macOS 13.0+** (Ventura or later)
- **Xcode 15.0+**
- Swift 5.9+

## Build & Run

### Option A: Open the included Xcode project

1. Open `Pomodoro.xcodeproj` in Xcode
2. Select the **Pomodoro** scheme and **My Mac** as the destination
3. Press **⌘R** to build and run

### Option B: Create a new Xcode project from scratch

If you prefer to start fresh:

1. Open Xcode → **File → New → Project**
2. Choose **macOS → App**, click Next
3. Set:
   - Product Name: `Pomodoro`
   - Interface: **SwiftUI**
   - Language: **Swift**
4. Delete the auto-generated `ContentView.swift`
5. Copy all `.swift` files from `Pomodoro/Sources/` into the project
6. Replace `Info.plist` with the one provided (sets `LSUIElement = YES`)
7. Add the `Pomodoro.entitlements` file to the project
8. Build and run (**⌘R**)

## Project Structure

```
Pomodoro/
├── Sources/
│   ├── PomodoroApp.swift          # @main entry point
│   ├── AppDelegate.swift          # Sets up NSStatusItem + NSPopover
│   ├── MenuBarController.swift    # Manages menu bar item and popover
│   ├── TimerViewModel.swift       # Core timer logic (ObservableObject)
│   ├── TimerView.swift            # Main popover UI (progress ring + controls)
│   ├── SettingsView.swift         # Inline settings panel
│   ├── ProgressRing.swift         # Reusable circular progress component
│   ├── NotificationManager.swift  # macOS notifications + sound
│   └── Constants.swift            # Defaults, colors, sizing
├── Assets.xcassets/               # App icon asset catalog
├── Info.plist                     # LSUIElement = YES (no Dock icon)
└── Pomodoro.entitlements          # App sandbox
```

## Usage

- Click the 🍅 in the menu bar to open the popover
- Press **Play** to start a 25-minute focus session
- The menu bar shows a live countdown: `🍅 18:32`
- When the session ends, you'll hear a chime and see a notification
- Breaks start automatically (if enabled) or wait for you to press Play
- Click the **gear icon** to adjust durations and preferences
- Click outside the popover to dismiss it

## Customization

All settings are persisted via `UserDefaults` and survive app restarts:

| Setting | Default |
|---------|---------|
| Focus duration | 25 min |
| Short break | 5 min |
| Long break | 15 min |
| Pomodoros before long break | 4 |
| Auto-start breaks | Off |
| Auto-start pomodoros | Off |
| Sound on session end | On |
| Tick sound | Off |
| Show timer in menu bar | On |
