#!/bin/bash
set -e

echo "Removing Wallpaper Engine KDE Plugin..."

# Remove QML library
sudo rm -rf /usr/lib64/qt6/qml/com/github/catsout/wallpaperEngineKde

# Remove wallpaper plugin
rm -rf "$HOME/.local/share/plasma/wallpapers/com.github.catsout.wallpaperEngineKde"

# Clean plasma config if active
sed -i '/wallpaperEngineKde/d' ~/.config/plasma-org.kde.plasma.desktop-appletsrc 2>/dev/null || true

echo "Done. Log out and back in to complete removal."
