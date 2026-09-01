#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

print_step() {
    echo ""
    echo "============================================"
    echo "  $1"
    echo "============================================"
    echo ""
}

print_step "Wallpaper Engine KDE Plugin Installer (Fedora/Nobara)"

# ── Check for KDE Plasma ──
if ! command -v plasmashell &>/dev/null; then
    echo "[ERROR] KDE Plasma not found. This plugin requires KDE Plasma 6."
    exit 1
fi

# ── Step 1: Install runtime dependencies ──
print_step "Step 1: Installing runtime dependencies"
sudo dnf install -y mpv mpv-libs qt6-qtwebengine qt6-qtwebsockets-devel qt6-qtdeclarative lz4-libs vulkan-loader

# Python websockets (needed by plugin helper)
pip install --user websockets 2>/dev/null || pip3 install --user websockets 2>/dev/null || true

# ── Step 2: Install compiled QML module (lib) ──
print_step "Step 2: Installing plugin library"
QML_DIR="/usr/lib64/qt6/qml/com/github/catsout/wallpaperEngineKde"
sudo mkdir -p "$QML_DIR"
sudo cp "$SCRIPT_DIR/prebuilt/lib/libWallpaperEngineKde.so" "$QML_DIR/"
sudo cp "$SCRIPT_DIR/prebuilt/lib/qmldir" "$QML_DIR/"

# ── Step 3: Install KDE wallpaper plugin (QML frontend) ──
print_step "Step 3: Installing wallpaper plugin"
PLUGIN_DIR="$HOME/.local/share/plasma/wallpapers/com.github.catsout.wallpaperEngineKde"
mkdir -p "$PLUGIN_DIR"
cp -r "$SCRIPT_DIR/prebuilt/plugin/"* "$PLUGIN_DIR/"

# ── Done ──
print_step "Installation complete!"

echo "Next steps:"
echo ""
echo "  1. Install Wallpaper Engine on Steam (Linux version)"
echo ""
echo "  2. IMPORTANT - In Steam:"
echo "     Right-click Wallpaper Engine -> Properties -> Beta"
echo "     -> select 'win 7 compatibility'"
echo "     THIS PREVENTS PLASMA CRASHES!"
echo ""
echo "  3. Subscribe to wallpapers on Steam Workshop"
echo ""
echo "  4. Restart Plasma:"
echo "     Log out and back in, or run: systemctl --user restart plasma-plasmashell.service"
echo ""
echo "  5. Right-click desktop -> Configure Desktop"
echo "     Change wallpaper type from 'Image' to 'Wallpaper Engine'"
echo "     Point it to your Steam library folder containing 'steamapps'"
echo ""
echo "  Default Steam path: ~/.local/share/Steam"
echo ""
echo "────────────────────────────────────────────"
echo "  If Plasma crashes, run (Ctrl+Alt+T):"
echo "  sed -i '/wallpaperEngineKde/d' ~/.config/plasma-org.kde.plasma.desktop-appletsrc && qdbus6 org.kde.Shutdown /Shutdown logout"
echo "────────────────────────────────────────────"
