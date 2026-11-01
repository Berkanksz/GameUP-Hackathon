#!/bin/bash
# Higher Ground - macOS / Linux Launcher

echo "========================================================"
echo "Higher Ground: Iklim Yolculugu / Climate Journey"
echo "========================================================"
echo ""

if command -v godot &> /dev/null; then
    exec godot --path "$(dirname "$0")"
elif [ -d "/Applications/Godot.app" ]; then
    exec /Applications/Godot.app/Contents/MacOS/Godot --path "$(dirname "$0")"
elif [ -d "$HOME/Applications/Godot.app" ]; then
    exec "$HOME/Applications/Godot.app/Contents/MacOS/Godot" --path "$(dirname "$0")"
else
    echo "[INFO] Godot 4 was not found in PATH or Applications."
    echo "To play on macOS:"
    echo "1. Download Godot 4 from https://godotengine.org/download/macos/"
    echo "2. Open Godot, click 'Import', select 'project.godot' from this folder."
    echo "3. Click 'Run' (or press F5)."
fi
