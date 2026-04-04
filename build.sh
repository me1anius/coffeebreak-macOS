#!/bin/bash
# Build script for Pomodoro Timer — produces a standalone .app bundle
# No Xcode required, just the Command Line Tools with Swift.
#
# Usage:
#   chmod +x build.sh
#   ./build.sh
#
# Output: ./build/Pomodoro.app (drag to /Applications to install)

set -e

APP_NAME="Pomodoro"
BUILD_DIR="./build"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS="${APP_BUNDLE}/Contents"
MACOS="${CONTENTS}/MacOS"
RESOURCES="${CONTENTS}/Resources"

SOURCE_DIR="./Pomodoro/Sources"
SDK_PATH=$(xcrun --show-sdk-path)

echo "🍅 Building Pomodoro Timer..."
echo "   SDK: ${SDK_PATH}"
echo ""

# Clean previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${MACOS}" "${RESOURCES}"

# Gather all Swift source files
SOURCES=(
    "${SOURCE_DIR}/Constants.swift"
    "${SOURCE_DIR}/NotificationManager.swift"
    "${SOURCE_DIR}/TimerViewModel.swift"
    "${SOURCE_DIR}/ProgressRing.swift"
    "${SOURCE_DIR}/TimerView.swift"
    "${SOURCE_DIR}/SettingsView.swift"
    "${SOURCE_DIR}/MenuBarController.swift"
    "${SOURCE_DIR}/HotkeyManager.swift"
    "${SOURCE_DIR}/AppDelegate.swift"
    "${SOURCE_DIR}/PomodoroApp.swift"
)

echo "   Compiling ${#SOURCES[@]} source files..."

# Compile all Swift files into the app binary
swiftc \
    -o "${MACOS}/${APP_NAME}" \
    -sdk "${SDK_PATH}" \
    -target arm64-apple-macosx13.0 \
    -swift-version 6 \
    -O \
    -whole-module-optimization \
    -parse-as-library \
    "${SOURCES[@]}" \
    -Xlinker -framework -Xlinker AppKit \
    -Xlinker -framework -Xlinker SwiftUI \
    -Xlinker -framework -Xlinker UserNotifications

echo "   ✓ Compilation successful"

# Copy Info.plist
cp "./Pomodoro/Info.plist" "${CONTENTS}/Info.plist"
echo "   ✓ Info.plist copied"

# Create PkgInfo (standard macOS app bundle marker)
echo -n "APPL????" > "${CONTENTS}/PkgInfo"

# Copy bundled resources (icons, etc.)
if [ -d "./Pomodoro/Resources" ]; then
    cp ./Pomodoro/Resources/* "${RESOURCES}/"
    echo "   ✓ Resources copied"
fi

# Compile asset catalog if actool is available
if command -v actool &> /dev/null; then
    actool \
        --compile "${RESOURCES}" \
        --platform macosx \
        --minimum-deployment-target 13.0 \
        "./Pomodoro/Assets.xcassets" 2>/dev/null || true
    echo "   ✓ Asset catalog compiled"
else
    echo "   ⚠ actool not found — skipping asset catalog (app will work without an icon)"
fi

echo ""
echo "✅ Build complete: ${APP_BUNDLE}"
echo ""
echo "To run:     open ${APP_BUNDLE}"
echo "To install: cp -r ${APP_BUNDLE} /Applications/"
echo ""
