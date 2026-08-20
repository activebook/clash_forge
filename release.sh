#!/bin/bash
set -e

# Load environment variables if present
[ -f ./env ] && source ./env

echo "=========================================="
echo "Clash Forge macOS Universal Release Script"
echo "=========================================="

# Extract clean version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//' | tr -d ' ')
TAG_NAME="v$VERSION"
echo "Target Release: $TAG_NAME (v$VERSION)"

# Run pre-release test suite
echo "1. Running automated verification test suite..."
http_proxy="" https_proxy="" all_proxy="" NO_PROXY="127.0.0.1,localhost" flutter test

# Build Universal macOS release bundle
echo "2. Compiling macOS Universal Release binary..."
http_proxy="" https_proxy="" all_proxy="" NO_PROXY="127.0.0.1,localhost" flutter build macos --release

APP_PATH="build/macos/Build/Products/Release/Clash Forge.app"
BINARY_PATH="$APP_PATH/Contents/MacOS/Clash Forge"

if [ ! -d "$APP_PATH" ]; then
    echo "ERROR: Compiled application bundle not found at $APP_PATH"
    exit 1
fi

# Verify Universal Mach-O architecture (x86_64 + arm64)
echo "3. Verifying Universal Mach-O architecture..."
ARCH_INFO=$(lipo -info "$BINARY_PATH")
echo "   $ARCH_INFO"
echo "$ARCH_INFO" | grep -q "x86_64" || { echo "ERROR: Missing x86_64 architecture"; exit 1; }
echo "$ARCH_INFO" | grep -q "arm64" || { echo "ERROR: Missing arm64 architecture"; exit 1; }
echo "   Confirmed: Universal binary supports both Intel (x86_64) and Apple Silicon (arm64)."

# Package distribution artifacts
echo "4. Packaging distribution artifacts into dist/..."
mkdir -p dist
rm -rf dist/*

DMG_NAME="Clash-Forge-${TAG_NAME}-macOS-Universal.dmg"
ZIP_NAME="Clash-Forge-${TAG_NAME}-macOS-Universal.zip"

echo "   Creating ZIP archive ($ZIP_NAME)..."
ditto -c -k --keepParent "$APP_PATH" "dist/$ZIP_NAME"

echo "   Creating DMG installer ($DMG_NAME)..."
DMG_TEMP="build/dmg_temp"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"
cp -R "$APP_PATH" "$DMG_TEMP/"
ln -s /Applications "$DMG_TEMP/Applications"

hdiutil create -volname "Clash Forge" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "dist/$DMG_NAME"
rm -rf "$DMG_TEMP"

echo "   Generating SHA256 cryptographic checksums..."
cd dist
shasum -a 256 "$DMG_NAME" "$ZIP_NAME" > SHA256SUMS.txt
cat SHA256SUMS.txt
cd ..

echo "5. Publishing GitHub Release $TAG_NAME..."
gh release create "$TAG_NAME" \
    --title "Clash Forge $TAG_NAME - macOS Universal" \
    --generate-notes \
    dist/"$DMG_NAME" \
    dist/"$ZIP_NAME" \
    dist/SHA256SUMS.txt

echo "=========================================="
echo "Release $TAG_NAME published successfully!"
echo "Artifacts:"
echo " - dist/$DMG_NAME"
echo " - dist/$ZIP_NAME"
echo " - dist/SHA256SUMS.txt"
echo "=========================================="
