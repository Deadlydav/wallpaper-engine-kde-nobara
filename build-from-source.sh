#!/bin/bash
set -e

# Wallpaper Engine KDE Plugin Installer for Fedora/Nobara
# Installs the wallpaper-engine-kde-plugin with scene renderer support
# Uses zip downloads as fallback when git clone fails

WORK_DIR="$HOME/Downloads/wallpaper-engine-kde-build"
PLUGIN_REPO="https://github.com/catsout/wallpaper-engine-kde-plugin"
SCENE_REPO="https://github.com/catsout/wallpaper-scene-renderer"
SPIRV_REPO="https://github.com/KhronosGroup/SPIRV-Reflect"
NLOHMANN_REPO="https://github.com/nlohmann/json"
MINIAUDIO_REPO="https://github.com/mackron/miniaudio"
GLSLANG_REPO="https://github.com/KhronosGroup/glslang"
EIGEN_REPO="https://gitlab.com/libeigen/eigen"

MAX_RETRIES=3
RETRY_DELAY=5

print_step() {
    echo ""
    echo "============================================"
    echo "  $1"
    echo "============================================"
    echo ""
}

print_error() {
    echo "[ERROR] $1" >&2
}

print_info() {
    echo "[INFO] $1"
}

# Retry a command up to MAX_RETRIES times
retry() {
    local desc="$1"
    shift
    for i in $(seq 1 $MAX_RETRIES); do
        if "$@"; then
            return 0
        fi
        if [ "$i" -lt "$MAX_RETRIES" ]; then
            print_info "Attempt $i/$MAX_RETRIES for '$desc' failed. Retrying in ${RETRY_DELAY}s..."
            sleep $RETRY_DELAY
        fi
    done
    print_error "'$desc' failed after $MAX_RETRIES attempts."
    return 1
}

# Try git clone first, fall back to zip download
clone_or_download() {
    local repo_url="$1"
    local dest_dir="$2"
    local branch="${3:-main}"

    if [ -d "$dest_dir" ] && [ "$(ls -A "$dest_dir" 2>/dev/null)" ]; then
        print_info "Directory $dest_dir already exists and is not empty, skipping."
        return 0
    fi

    rm -rf "$dest_dir"

    # Try git clone first
    print_info "Trying git clone: $repo_url"
    if retry "git clone $repo_url" git clone --depth 1 "$repo_url" "$dest_dir" 2>/dev/null; then
        print_info "Git clone succeeded."
        return 0
    fi

    # Fall back to zip download
    print_info "Git clone failed, trying zip download..."
    local zip_url="${repo_url}/archive/refs/heads/${branch}.zip"
    local zip_file="/tmp/$(basename "$repo_url")-${branch}.zip"
    local extract_name="$(basename "$repo_url")-${branch}"

    # Handle gitlab URLs differently
    if echo "$repo_url" | grep -q "gitlab"; then
        zip_url="${repo_url}/-/archive/${branch}/$(basename "$repo_url")-${branch}.zip"
    fi

    if retry "download $zip_url" curl -L -f -o "$zip_file" "$zip_url"; then
        local tmp_extract="/tmp/extract_$(basename "$repo_url")"
        rm -rf "$tmp_extract"
        unzip -q -o "$zip_file" -d "$tmp_extract"

        # Find the extracted directory (name may vary)
        local extracted=$(find "$tmp_extract" -mindepth 1 -maxdepth 1 -type d | head -1)
        if [ -z "$extracted" ]; then
            print_error "Zip extraction failed for $repo_url"
            rm -rf "$tmp_extract" "$zip_file"
            return 1
        fi

        mv "$extracted" "$dest_dir"
        rm -rf "$tmp_extract" "$zip_file"
        print_info "Zip download succeeded."
        return 0
    fi

    # Fall back: try master branch
    if [ "$branch" = "main" ]; then
        print_info "Trying 'master' branch instead..."
        clone_or_download "$repo_url" "$dest_dir" "master"
        return $?
    fi

    print_error "Could not download $repo_url"
    return 1
}

# ──────────────────────────────────────────────
# Step 1: Install dependencies
# ──────────────────────────────────────────────
print_step "Step 1: Installing dependencies"

sudo dnf install -y \
    git cmake extra-cmake-modules \
    plasma-workspace-devel libplasma-devel \
    mpv-devel vulkan-headers lz4-devel \
    qt6-qtwebengine-devel qt6-qtwebsockets-devel qt6-qtdeclarative-devel \
    unzip curl

# Python websockets module (needed by the KDE plugin QML helper)
pip install --user websockets 2>/dev/null || pip3 install --user websockets 2>/dev/null || true

# ──────────────────────────────────────────────
# Step 2: Download sources
# ──────────────────────────────────────────────
print_step "Step 2: Downloading sources"

mkdir -p "$WORK_DIR"

# Main plugin
clone_or_download "$PLUGIN_REPO" "$WORK_DIR/wallpaper-engine-kde-plugin"

# Scene renderer (submodule)
SCENE_DIR="$WORK_DIR/wallpaper-engine-kde-plugin/src/backend_scene"
clone_or_download "$SCENE_REPO" "$SCENE_DIR" "master"

# Nested submodules (third_party)
THIRD_PARTY="$SCENE_DIR/third_party"
clone_or_download "$SPIRV_REPO"   "$THIRD_PARTY/SPIRV-Reflect"
clone_or_download "$NLOHMANN_REPO" "$THIRD_PARTY/nlohmann"
clone_or_download "$MINIAUDIO_REPO" "$THIRD_PARTY/miniaudio"
clone_or_download "$GLSLANG_REPO"  "$THIRD_PARTY/glslang"
clone_or_download "$EIGEN_REPO"    "$THIRD_PARTY/Eigen"

# ──────────────────────────────────────────────
# Step 3: Patch GCC 15 compatibility (missing cassert)
# ──────────────────────────────────────────────
print_step "Step 3: Patching GCC 15 compatibility"

patch_count=0
while IFS= read -r -d '' file; do
    if grep -q 'assert(' "$file" && ! grep -q '#include <cassert>' "$file" && ! grep -q '#include <assert.h>' "$file"; then
        sed -i '1s/^/#include <cassert>\n/' "$file"
        patch_count=$((patch_count + 1))
        print_info "Patched: $(basename "$file")"
    fi
done < <(find "$SCENE_DIR/src" -type f \( -name '*.cpp' -o -name '*.hpp' -o -name '*.h' \) -print0)

print_info "Patched $patch_count files with missing <cassert>"

# ──────────────────────────────────────────────
# Step 4: Build
# ──────────────────────────────────────────────
print_step "Step 4: Building"

BUILD_DIR="$WORK_DIR/wallpaper-engine-kde-plugin/build"
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

cmake .. -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release
make -j"$(nproc)"

# ──────────────────────────────────────────────
# Step 5: Install
# ──────────────────────────────────────────────
print_step "Step 5: Installing"

sudo make install

# ──────────────────────────────────────────────
# Step 6: Install KDE wallpaper plugin (QML frontend)
# ──────────────────────────────────────────────
print_step "Step 6: Installing KDE wallpaper plugin (QML frontend)"

PLUGIN_SRC="$WORK_DIR/wallpaper-engine-kde-plugin/plugin"
PLUGIN_DEST="$HOME/.local/share/plasma/wallpapers/com.github.catsout.wallpaperEngineKde"

if [ -d "$PLUGIN_SRC" ]; then
    mkdir -p "$PLUGIN_DEST"
    cp -r "$PLUGIN_SRC"/* "$PLUGIN_DEST"/
    print_info "QML plugin installed to $PLUGIN_DEST"
else
    print_info "QML plugin directory not found in source. Install it manually from the KDE Store."
fi

# ──────────────────────────────────────────────
# Done
# ──────────────────────────────────────────────
print_step "Installation complete!"

echo "Next steps:"
echo "  1. Make sure Wallpaper Engine is installed on Steam (Linux)"
echo "  2. In Steam: right-click Wallpaper Engine -> Properties -> Beta"
echo "     -> select 'win 7 compatibility' (prevents Plasma crashes)"
echo "  3. Subscribe to wallpapers on Steam Workshop"
echo "  4. Restart Plasma: log out/in or run 'plasmashell --replace &'"
echo "  5. Right-click desktop -> Configure Desktop -> change wallpaper"
echo "     type from 'Image' to 'Wallpaper Engine'"
echo "  6. Point it to your Steam library folder containing 'steamapps'"
echo ""
echo "If Plasma crashes, run in a terminal (Ctrl+Alt+T):"
echo "  sed -i '/wallpaperEngineKde/d' ~/.config/plasma-org.kde.plasma.desktop-appletsrc && qdbus6 org.kde.Shutdown /Shutdown logout"
echo ""
echo "Build files are in: $WORK_DIR"
echo "You can safely delete them after installation."
