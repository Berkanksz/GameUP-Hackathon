#!/bin/bash
# Higher Ground - macOS / Linux Launcher

DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================================"
echo "Higher Ground: Iklim Yolculugu / Climate Journey"
echo "========================================================"
echo ""

GODOT_BIN=""
if command -v godot &> /dev/null; then
    GODOT_BIN="godot"
elif [ -d "/Applications/Godot.app" ]; then
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
elif [ -d "$HOME/Applications/Godot.app" ]; then
    GODOT_BIN="$HOME/Applications/Godot.app/Contents/MacOS/Godot"
fi

if [ -z "$GODOT_BIN" ]; then
    echo "[HATA / ERROR] Godot 4 bulunamadi."
    echo "Lutfen Godot 4 indirin: https://godotengine.org/download/"
    echo "Ardindan Godot ile 'project.godot' dosyasini acabilirsiniz."
    exit 1
fi

# İlk çalıştırmada varlıkların taranması ve içe aktarılması (First-time asset import)
if [ ! -d "$DIR/.godot/imported" ]; then
    echo "Ilk calistirma hazirligi yapiliyor (varliklar ice aktariliyor)..."
    "$GODOT_BIN" --headless --editor --quit --path "$DIR"
fi

# Oyunu baslat
exec "$GODOT_BIN" --path "$DIR"
