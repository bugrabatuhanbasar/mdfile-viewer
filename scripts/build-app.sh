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

# Generate AppIcon.icns from the source PNG at assets/AppIcon.png.
ICON_SRC="assets/AppIcon.png"
if [ -f "$ICON_SRC" ]; then
    echo "==> generating AppIcon.icns"
    ICONSET="$(mktemp -d)/AppIcon.iconset"
    mkdir -p "$ICONSET"
    for spec in \
        "16 icon_16x16.png" \
        "32 icon_16x16@2x.png" \
        "32 icon_32x32.png" \
        "64 icon_32x32@2x.png" \
        "128 icon_128x128.png" \
        "256 icon_128x128@2x.png" \
        "256 icon_256x256.png" \
        "512 icon_256x256@2x.png" \
        "512 icon_512x512.png" \
        "1024 icon_512x512@2x.png"; do
        size="${spec%% *}"
        name="${spec#* }"
        sips -z "$size" "$size" "$ICON_SRC" --out "$ICONSET/$name" >/dev/null
    done
    iconutil -c icns "$ICONSET" -o "$APP_DIR/Contents/Resources/AppIcon.icns"
    rm -rf "$(dirname "$ICONSET")"
fi

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
