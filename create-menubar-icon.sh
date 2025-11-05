#!/bin/bash

# Create a simple menubar icon using ImageMagick or native macOS tools
# This creates a template icon suitable for menu bars

ICON_SIZE=18

# Check if ImageMagick is available
if command -v convert &> /dev/null; then
    echo "Using ImageMagick to create menu bar icon..."
    
    # Create a simple HLS icon (play button with signal waves)
    convert -size ${ICON_SIZE}x${ICON_SIZE} xc:transparent \
        -fill black \
        -draw "polygon 5,4 5,14 13,9" \
        -draw "path 'M 14,6 Q 16,9 14,12'" \
        -draw "path 'M 15,4 Q 18,9 15,14'" \
        menubar-icon.png
    
    echo "Menu bar icon created: menubar-icon.png"
elif command -v sips &> /dev/null; then
    echo "Using sips to resize favicon for menu bar..."
    
    # Just resize the favicon
    sips -z $ICON_SIZE $ICON_SIZE favicon.png --out menubar-icon.png
    
    echo "Menu bar icon created: menubar-icon.png"
else
    echo "Neither ImageMagick nor sips available."
    echo "The app will use text 'HLS' in the menu bar."
    echo "You can manually create a menubar-icon.png (18x18 or 36x36 for retina) for better appearance."
fi
