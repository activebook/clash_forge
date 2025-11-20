#!/bin/bash

set -e

# Load environment variables
source ./env

echo "Clash Forge macOS Release Script"
echo "================================="

# Get version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
echo "Version: $VERSION"

# Build the app(mannually)
#echo "Building macOS release..."
#flutter build macos --release

# Define paths
APP_PATH="build/macos/Build/Products/Release/Clash Forge.app"
ZIP_NAME="clash-forge-macos-v$VERSION.zip"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    exit 1
fi

# Zip the app (handle space in name)
echo "Creating zip archive: $ZIP_NAME"
zip -r "$ZIP_NAME" "build/macos/Build/Products/Release/Clash Forge.app"

# Create GitHub release
echo "Creating GitHub release..."
RELEASE_NOTES="Clash Forge macOS release v$VERSION

Changes since last release:
- See git log for details"

gh release create "v$VERSION" \
    --title "Clash Forge v$VERSION - macOS" \
    --notes "$RELEASE_NOTES" \
    "$ZIP_NAME"

echo "Release completed successfully!"
echo "Tag: v$VERSION"
echo "Archive: $ZIP_NAME"
