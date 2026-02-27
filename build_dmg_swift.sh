#!/bin/bash
set -e

APP_NAME="Pluck"
DMG_NAME="Pluck"
VERSION="2.0.0"
PROJECT_DIR="$(pwd)"
BUILD_DIR="${PROJECT_DIR}/build_swift"
ARCHIVE_PATH="${BUILD_DIR}/${APP_NAME}.xcarchive"
EXPORT_PATH="${BUILD_DIR}/export"
DMG_DIR="${BUILD_DIR}/dmg_staging"
DMG_OUTPUT="${PROJECT_DIR}/${DMG_NAME}-${VERSION}.dmg"

echo "=== Pluck .dmg Builder ==="
echo ""

# Step 1: Clean
echo "[1/5] Cleaning previous builds..."
rm -rf "$BUILD_DIR" "$DMG_OUTPUT"

# Step 2: Build archive
echo "[2/5] Building Xcode archive..."
xcodebuild archive \
    -project "${PROJECT_DIR}/Pluck.xcodeproj" \
    -scheme "Pluck" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGN_IDENTITY="-" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    ONLY_ACTIVE_ARCH=NO \
    2>&1 | tail -20

if [ ! -d "$ARCHIVE_PATH" ]; then
    echo "ERROR: Archive was not created. Check build output above."
    exit 1
fi

echo "    Archive created: $ARCHIVE_PATH"

# Step 3: Extract .app from archive
echo "[3/5] Extracting .app bundle..."
APP_PATH="${ARCHIVE_PATH}/Products/Applications/${APP_NAME}.app"

if [ ! -d "$APP_PATH" ]; then
    # Try alternate location
    APP_PATH="${ARCHIVE_PATH}/Products/usr/local/bin/${APP_NAME}.app"
fi

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: .app not found in archive. Trying direct build..."
    
    xcodebuild build \
        -project "${PROJECT_DIR}/Pluck.xcodeproj" \
        -scheme "Pluck" \
        -configuration Release \
        -derivedDataPath "${BUILD_DIR}/DerivedData" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        CODE_SIGNING_ALLOWED=NO \
        2>&1 | tail -20
    
    APP_PATH=$(find "${BUILD_DIR}/DerivedData" -name "${APP_NAME}.app" -type d | head -1)
    
    if [ -z "$APP_PATH" ] || [ ! -d "$APP_PATH" ]; then
        echo "ERROR: Could not find .app bundle."
        exit 1
    fi
fi

echo "    .app found: $APP_PATH"

# Step 4: Bundle yt-dlp and ffmpeg binaries
echo "[4/5] Bundling binaries..."
BIN_DIR="${APP_PATH}/Contents/Resources/bin"
mkdir -p "$BIN_DIR"

# Bundle yt-dlp (standalone binary, no Python needed)
echo "    Downloading standalone yt-dlp binary..."
curl -L -o "$BIN_DIR/yt-dlp" "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos"
if [ -f "$BIN_DIR/yt-dlp" ] && [ -s "$BIN_DIR/yt-dlp" ]; then
    chmod +x "$BIN_DIR/yt-dlp"
    echo "    Bundled standalone yt-dlp"
else
    echo "    ERROR: Failed to download yt-dlp standalone binary."
    exit 1
fi

# Bundle ffmpeg
FFMPEG_PATH=$(which ffmpeg 2>/dev/null || true)
if [ -n "$FFMPEG_PATH" ]; then
    cp "$FFMPEG_PATH" "$BIN_DIR/ffmpeg"
    chmod +x "$BIN_DIR/ffmpeg"
    echo "    Bundled ffmpeg: $FFMPEG_PATH"
else
    echo "    WARNING: ffmpeg not found. Users will need to install it separately."
fi

# Bundle ffprobe
FFPROBE_PATH=$(which ffprobe 2>/dev/null || true)
if [ -n "$FFPROBE_PATH" ]; then
    cp "$FFPROBE_PATH" "$BIN_DIR/ffprobe"
    chmod +x "$BIN_DIR/ffprobe"
    echo "    Bundled ffprobe"
fi

# Strip quarantine attributes from all bundled binaries
xattr -cr "$BIN_DIR" 2>/dev/null || true
echo "    Stripped quarantine attributes"

# Step 5: Create DMG
echo "[5/5] Creating .dmg..."
mkdir -p "$DMG_DIR"
cp -R "$APP_PATH" "$DMG_DIR/"
ln -s /Applications "$DMG_DIR/Applications"

hdiutil create \
    -volname "Pluck" \
    -srcfolder "$DMG_DIR" \
    -ov \
    -format UDZO \
    "$DMG_OUTPUT"

# Clean up
rm -rf "$BUILD_DIR"

echo ""
echo "=== Build Complete ==="
echo "DMG: $DMG_OUTPUT"
SIZE=$(du -h "$DMG_OUTPUT" | cut -f1)
echo "Size: $SIZE"
echo ""
echo "To install: Open the .dmg and drag Pluck to Applications."
