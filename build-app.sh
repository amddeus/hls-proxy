#!/bin/bash

# Build script for HLS Proxy macOS app
# This script must be run on macOS with Xcode installed

set -e

echo "Building HLS Proxy.app..."

# Define paths
APP_NAME="HLSProxy.app"
CONTENTS_DIR="$APP_NAME/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Create directory structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# Compile Swift app with ARM64 optimizations
echo "Compiling Swift application with ARM64 optimizations..."
# -O: Optimize for speed
# -wmo: Whole Module Optimization (faster, smaller binary)
# Uses Grand Central Dispatch (GCD) with Quality of Service for Apple Silicon
swiftc -O -wmo -o "$MACOS_DIR/HLSProxyApp" HLSProxyApp.swift -framework Cocoa

# Copy Info.plist (already in place from repository)
# No need to copy as it should already exist in the correct location

# Copy resources
echo "Copying resources..."
if [ ! -f "hls-proxy" ]; then
    echo "Error: hls-proxy binary not found!"
    exit 1
fi
cp hls-proxy "$RESOURCES_DIR/"

for file in default.json local.json groups.json favicon.png iptv.m3u8 epg.xml.gz; do
    if [ -f "$file" ]; then
        cp "$file" "$RESOURCES_DIR/"
    else
        echo "Warning: $file not found, skipping..."
    fi
done

# Create menu bar icon if script exists
if [ -f "create-menubar-icon.sh" ]; then
    ./create-menubar-icon.sh
    if [ -f "menubar-icon.png" ]; then
        cp menubar-icon.png "$RESOURCES_DIR/"
    fi
fi

# Copy plugins directory if it exists
if [ -d "plugins" ]; then
    cp -r plugins "$RESOURCES_DIR/"
else
    echo "Warning: plugins directory not found"
fi

# Copy epg-cache directory if it exists
if [ -d "epg-cache" ]; then
    cp -r epg-cache "$RESOURCES_DIR/"
else
    echo "Warning: epg-cache directory not found, will be created at runtime"
fi

# Create icon from favicon.png (if sips is available)
echo "Creating app icon..."
if command -v sips &> /dev/null && command -v iconutil &> /dev/null; then
    # Create iconset directory
    ICONSET_DIR="AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"
    
    # Generate different sizes
    sips -z 16 16 favicon.png --out "$ICONSET_DIR/icon_16x16.png" 2>/dev/null || cp favicon.png "$ICONSET_DIR/icon_16x16.png"
    sips -z 32 32 favicon.png --out "$ICONSET_DIR/icon_16x16@2x.png" 2>/dev/null || cp favicon.png "$ICONSET_DIR/icon_16x16@2x.png"
    sips -z 32 32 favicon.png --out "$ICONSET_DIR/icon_32x32.png" 2>/dev/null || cp favicon.png "$ICONSET_DIR/icon_32x32.png"
    sips -z 64 64 favicon.png --out "$ICONSET_DIR/icon_32x32@2x.png" 2>/dev/null || cp favicon.png "$ICONSET_DIR/icon_32x32@2x.png"
    sips -z 128 128 favicon.png --out "$ICONSET_DIR/icon_128x128.png" 2>/dev/null || cp favicon.png "$ICONSET_DIR/icon_128x128.png"
    sips -z 256 256 favicon.png --out "$ICONSET_DIR/icon_128x128@2x.png" 2>/dev/null || cp favicon.png "$ICONSET_DIR/icon_128x128@2x.png"
    sips -z 256 256 favicon.png --out "$ICONSET_DIR/icon_256x256.png" 2>/dev/null || cp favicon.png "$ICONSET_DIR/icon_256x256.png"
    sips -z 512 512 favicon.png --out "$ICONSET_DIR/icon_256x256@2x.png" 2>/dev/null || cp favicon.png "$ICONSET_DIR/icon_256x256@2x.png"
    sips -z 512 512 favicon.png --out "$ICONSET_DIR/icon_512x512.png" 2>/dev/null || cp favicon.png "$ICONSET_DIR/icon_512x512.png"
    sips -z 1024 1024 favicon.png --out "$ICONSET_DIR/icon_512x512@2x.png" 2>/dev/null || cp favicon.png "$ICONSET_DIR/icon_512x512@2x.png"
    
    # Create icns file
    iconutil -c icns "$ICONSET_DIR" -o "$RESOURCES_DIR/AppIcon.icns"
    
    # Clean up
    rm -rf "$ICONSET_DIR"
    
    echo "App icon created successfully"
else
    echo "Warning: sips or iconutil not found. Icon will not be created."
    echo "You can manually create AppIcon.icns and place it in $RESOURCES_DIR/"
fi

# Make the binary executable
chmod +x "$RESOURCES_DIR/hls-proxy"
chmod +x "$MACOS_DIR/HLSProxyApp"

# Remove quarantine attributes to avoid "damaged" error
echo "Removing quarantine attributes..."
xattr -cr "$APP_NAME" 2>/dev/null || echo "Note: xattr command not available or no attributes to remove"

echo ""
echo "Build complete! Application created at: $APP_NAME"
echo ""
echo "To install, drag $APP_NAME to your Applications folder."
echo "To run from command line: open $APP_NAME"
echo ""
echo "If you get a \"damaged\" error, run: xattr -cr $APP_NAME"
echo ""
