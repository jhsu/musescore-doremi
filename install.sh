#!/bin/bash
#
# Install/update the Jianpu Labels MuseScore plugin from GitHub
#
# Usage: ./install.sh
#

set -e

PLUGIN_URL="https://raw.githubusercontent.com/jhsu/musescore-doremi/refs/heads/main/doremi.qml"
PLUGIN_DIR="$HOME/Documents/MuseScore3/Plugins"
PLUGIN_FILE="doremi.qml"

echo "Jianpu Labels Plugin Installer"
echo "=============================="

# Create plugin directory if it doesn't exist
if [ ! -d "$PLUGIN_DIR" ]; then
    echo "Creating plugin directory: $PLUGIN_DIR"
    mkdir -p "$PLUGIN_DIR"
fi

# Download the latest version
echo "Downloading latest version from GitHub..."
if command -v curl &> /dev/null; then
    curl -fsSL "$PLUGIN_URL" -o "$PLUGIN_DIR/$PLUGIN_FILE"
elif command -v wget &> /dev/null; then
    wget -q "$PLUGIN_URL" -O "$PLUGIN_DIR/$PLUGIN_FILE"
else
    echo "Error: Neither curl nor wget found. Please install one of them."
    exit 1
fi

echo "Plugin installed to: $PLUGIN_DIR/$PLUGIN_FILE"
echo ""
echo "Next steps:"
echo "  1. Open MuseScore 3"
echo "  2. Go to Plugins > Plugin Manager"
echo "  3. Enable 'Jianpu Labels'"
echo "  4. Restart MuseScore if needed"
echo ""
echo "Done!"
