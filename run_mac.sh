#!/bin/bash
# Higher Ground - macOS / Linux Launcher

DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"

echo "========================================================"
echo "Higher Ground: Iklim Yolculugu / Climate Journey"
echo "========================================================"
echo ""

GODOT_BIN=""
if [ -d "$DIR/Godot.app/Contents/MacOS/Godot" ]; then
    GODOT_BIN="$DIR/Godot.app/Contents/MacOS/Godot"
elif command -v godot &> /dev/null; then
    GODOT_BIN="godot"
elif [ -d "/Applications/Godot.app" ]; then
    GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
elif [ -d "$HOME/Applications/Godot.app" ]; then
    GODOT_BIN="$HOME/Applications/Godot.app/Contents/MacOS/Godot"
fi

if [ -z "$GODOT_BIN" ]; then
    echo "[BILGI / INFO] Bilgisayarinizda Godot bulunamadi."
    echo "Oyun motoru otomatik olarak indiriliyor (tek seferlik, ~55 MB)..."
    echo "Downloading portable game runner, please wait..."
    echo ""
    if command -v curl &> /dev/null; then
        curl -L -o godot_mac.zip "https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_macos.universal.zip"
        if [ -f "godot_mac.zip" ]; then
            unzip -q godot_mac.zip
            rm -f godot_mac.zip
            if [ -d "Godot_v4.7.2-stable_macos.universal.app" ]; then
                mv "Godot_v4.7.2-stable_macos.universal.app" "Godot.app"
            fi
            if [ -d "$DIR/Godot.app/Contents/MacOS/Godot" ]; then
                GODOT_BIN="$DIR/Godot.app/Contents/MacOS/Godot"
            fi
        fi
    fi
fi

if [ -z "$GODOT_BIN" ]; then
    echo "[HATA / ERROR] Godot 4 bulunamadi."
    echo "Lutfen Godot 4 indirin: https://godotengine.org/download/"
    echo "Ardindan Godot ile 'project.godot' dosyasini acabilirsiniz."
    exit 1
fi

# Ilk calistirmada varliklarin taranmasi ve derlenmesi (First-time asset import)
if [ ! -d "$DIR/.godot/imported" ]; then
    echo ""
    echo "Ilk calistirma hazirligi yapiliyor (varliklar derleniyor, 2-3 saniye)..."
    echo "Preparing assets for first run, please wait..."
    "$GODOT_BIN" --headless --editor --quit --path "$DIR"
fi

echo ""
echo "Oyun baslatiliyor / Launching game..."
exec "$GODOT_BIN" --path "$DIR"
