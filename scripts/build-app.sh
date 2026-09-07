#!/usr/bin/env bash
set -euo pipefail

# Build MDFileViewer.app — a native macOS .app bundle around the SwiftPM executable.
# Usage: ./scripts/build-app.sh [--install]
#   --install  copy the built .app to /Applications

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

APP_NAME="MDFileViewer"
APP_DIR="build/${APP_NAME}.app"
BIN_NAME="MDFileViewer"

echo "==> swift build -c release"
swift build -c release --product "$BIN_NAME"

BIN_PATH="$(swift build -c release --product "$BIN_NAME" --show-bin-path)/$BIN_NAME"

echo "==> assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$BIN_PATH" "$APP_DIR/Contents/MacOS/$BIN_NAME"
cp scripts/Info.plist "$APP_DIR/Contents/Info.plist"

# Copy HTML/CSS/JS resources directly into the .app's Resources folder;
# the app reads them via Bundle.main.
cp -R Sources/MDFileViewer/Resources/. "$APP_DIR/Contents/Resources/"

echo "==> ad-hoc codesign"
codesign --force --deep --sign - "$APP_DIR" >/dev/null

echo "==> done: $APP_DIR"

if [ "${1:-}" = "--install" ]; then
    echo "==> installing to /Applications"
    rm -rf "/Applications/${APP_NAME}.app"
    cp -R "$APP_DIR" "/Applications/${APP_NAME}.app"
    /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister \
        -f "/Applications/${APP_NAME}.app" || true
    echo "==> installed. Right-click a .md file → Open With → ${APP_NAME}"
fi
