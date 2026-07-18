# Wallpaper Engine KDE Plugin for Fedora/Nobara

> **Note:** This package was built with the help of AI (Claude). Use at your own risk, but it works great for me!

Prebuilt package and installer for the [Wallpaper Engine](https://store.steampowered.com/app/431960/Wallpaper_Engine/) KDE Plasma 6 plugin on Fedora/Nobara Linux.

Getting this plugin working on Fedora/Nobara requires compiling from source since no RPM packages are provided upstream. This repo provides **prebuilt binaries** so you don't have to, along with a build-from-source script if you prefer.

## Prebuilt for

- **Nobara 43** (Fedora 43 based) and **Nobara 44** (Fedora 44 based, confirmed working)
- **KDE Plasma 6.5–6.7** / **Qt 6.10–6.11**
- **GCC 15** (patched for `<cassert>` compatibility)

> If you're on a different Fedora/Nobara version or a different Qt/Plasma version, use the [build from source](#build-from-source) method instead.

## Prerequisites

- [Wallpaper Engine](https://store.steampowered.com/app/431960/Wallpaper_Engine/) installed on Steam (**Linux version**)
- KDE Plasma 6 desktop environment

## Quick Install (Prebuilt)

```bash
git clone https://github.com/Deadlydav/wallpaper-engine-kde-nobara.git
cd wallpaper-engine-kde-nobara
chmod +x install.sh
./install.sh
```

Or download the repo as a zip and run:

```bash
unzip wallpaper-engine-kde-nobara-main.zip
cd wallpaper-engine-kde-nobara-main
chmod +x install.sh
./install.sh
```

The installer will:
1. Install runtime dependencies via `dnf`
2. Install the prebuilt plugin library to `/usr/lib64/qt6/qml/`
3. Install the QML wallpaper plugin to `~/.local/share/plasma/wallpapers/`

## Build from Source

If the prebuilt binaries don't work for your system:

```bash
chmod +x build-from-source.sh
./build-from-source.sh
```

This script handles everything: dependencies, downloading sources (with retry/fallback for GitHub issues), GCC 15 patching, building, and installing.

## Post-Install Setup

1. **Switch Wallpaper Engine to the compatibility beta (IMPORTANT):**
   - Steam -> Library -> right-click **Wallpaper Engine** -> Properties -> Beta
   - Select **"win 7 compatibility"**
   - **This prevents Plasma crashes!**

2. **Restart Plasma:**
   - Log out and back in, or run: `systemctl --user restart plasma-plasmashell.service`
   - (Avoid `plasmashell --replace &` — it orphans the session from systemd, leaving the shell unsupervised and unable to auto-recover if it crashes.)

3. **Configure your wallpaper:**
   - Right-click desktop -> **Configure Desktop and Wallpaper**
   - Change wallpaper type from **"Image"** to **"Wallpaper Engine"**
   - Point it to your Steam library folder (the one containing `steamapps`)
   - Default Steam path: `~/.local/share/Steam`

## Uninstall

```bash
chmod +x uninstall.sh
./uninstall.sh
```

## Troubleshooting

### Plasma crashes after selecting a wallpaper
Make sure you switched to the **"win 7 compatibility"** beta in Steam (see Post-Install Setup step 1).

If already crashed, open a terminal with `Ctrl+Alt+T` and run:
```bash
sed -i '/wallpaperEngineKde/d' ~/.config/plasma-org.kde.plasma.desktop-appletsrc && qdbus6 org.kde.Shutdown /Shutdown logout
```

### Black screen instead of wallpaper
- Ensure Wallpaper Engine is installed on Steam **on Linux** (not just Windows)
- Check that the plugin library is installed: `ls /usr/lib64/qt6/qml/com/github/catsout/wallpaperEngineKde/`
- Try a **video** type wallpaper first (simpler, most compatible)
- Check `journalctl --user -u plasma-plasmashell.service` (or just `journalctl`) for `Cannot load library ... libmpv.so.2: cannot open shared object file` — the `mpv` package alone doesn't provide this; you also need `mpv-libs` (see below)

### "module com.github.catsout.wallpaperEngineKde is not installed"
The plugin library is missing. Run `./install.sh` again or [build from source](#build-from-source).

### "ModuleNotFoundError: No module named 'websockets'"
```bash
pip install --user websockets
```

### "qtwebsocket (qml module) not found" / "Cannot load library ... libmpv.so.2"
`install.sh` installs both of these already, but if you hit this after an OS upgrade or a partial install:
```bash
sudo dnf install -y mpv-libs qt6-qtwebsockets-devel
systemctl --user restart plasma-plasmashell.service
```

## Credits & Upstream Sources

This project packages and patches existing open-source work for easier installation on Fedora/Nobara. All credit goes to the original authors:

| Component | Source | License |
|---|---|---|
| **wallpaper-engine-kde-plugin** | [catsout/wallpaper-engine-kde-plugin](https://github.com/catsout/wallpaper-engine-kde-plugin) | GPL-2.0 |
| **wallpaper-scene-renderer** | [catsout/wallpaper-scene-renderer](https://github.com/catsout/wallpaper-scene-renderer) | GPL-2.0 |
| **KDE Store plugin (QML frontend)** | [KDE Store - Wallpaper Engine for Plasma 6](https://store.kde.org/) by catsout | GPL-2.0 |
| **SteamOS prebuilt packages** (reference) | [slynobody/SteamOS-wallpaper-engine-kde-plugin](https://github.com/slynobody/SteamOS-wallpaper-engine-kde-plugin) | GPL-2.0 |

Third-party libraries used during compilation:

| Library | Source | License |
|---|---|---|
| **SPIRV-Reflect** | [KhronosGroup/SPIRV-Reflect](https://github.com/KhronosGroup/SPIRV-Reflect) | Apache-2.0 |
| **nlohmann/json** | [nlohmann/json](https://github.com/nlohmann/json) | MIT |
| **miniaudio** | [mackron/miniaudio](https://github.com/mackron/miniaudio) | MIT / Public Domain |
| **glslang** | [KhronosGroup/glslang](https://github.com/KhronosGroup/glslang) | BSD-3-Clause / MIT |
| **Eigen** | [libeigen/eigen](https://gitlab.com/libeigen/eigen) | MPL-2.0 |

## Patches Applied

- **GCC 15 compatibility**: Added missing `#include <cassert>` to source files in `wallpaper-scene-renderer` that use `assert()` without including the header (required for GCC 15+ which no longer implicitly includes it).

## License

This project is licensed under **GPL-2.0**, same as the upstream projects.
See [LICENSE](LICENSE) for details.
