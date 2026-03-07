# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Flake-based NixOS configuration managing three hosts:
- **zola** (laptop): Intel + NVIDIA hybrid graphics with Prime sync, full GUI
- **gary** (desktop): NVIDIA GT 630 using nouveau driver (open-source), full GUI
- **exupery** (WSL2): Headless development environment

## Build and Deployment

```bash
# Rebuild current system (must run as root or with sudo)
sudo nixos-rebuild switch --flake .#$(hostname)

# Rebuild specific host
sudo nixos-rebuild switch --flake .#zola
sudo nixos-rebuild switch --flake .#gary
sudo nixos-rebuild switch --flake .#exupery

# Update flake inputs (nixpkgs, home-manager, DMS, etc.)
nix flake update

# Check flake configuration without building
nix flake check

# Format Nix files
nixfmt *.nix **/*.nix
```

Home-manager is integrated via NixOS modules, so `nixos-rebuild` updates both system and user configurations.

## Architecture

### Module Organization

**System modules** (`/modules/`):
- `common.nix` - Base system config for all hosts (locale, users, packages, docker, ollama, podman)
- `head.nix` - GUI layer (Hyprland, DMS greeter, XDG portal, Steam, gamemode, pipewire audio)
- `audio.nix` - musnix for low-latency audio production
- `theme.nix` - Wallpaper theming options for DMS matugen integration

**Home-manager config** (`/home/`):
- `home.nix` - Base user config (git, direnv, VSCode/Cursor, fish shell)
- `head.nix` - GUI user layer (DMS, Hyprland config, PWA apps via Chrome)
- `dms-settings.nix` - Complete DMS preferences (exported declaratively from live config)
- `modules/hyprland.nix` - Hyprland window manager configuration (monitor setup, keybinds, workspaces)
- `modules/shell/` - Shell configurations (fish, zsh, starship prompt, yazi file manager, fastfetch)

**Host configs** (`/hosts/<hostname>/`):
- `configuration.nix` - Host-specific settings (GPU drivers, networking, bootloader)
- `hardware-configuration.nix` - Auto-generated hardware detection (do not manually edit)

### The "head" Pattern

This config uses a boolean `head` option to conditionally enable GUI (Hyprland/DMS) vs headless:

```nix
# In host configuration.nix:
head = true;  # Enables GUI modules (zola, gary)
head = false; # Headless (exupery WSL)
```

When `head = true`:
- System imports `/modules/head.nix` (Hyprland, DMS greeter, gaming, audio)
- Home-manager imports `/home/head.nix` (DMS shell, GUI apps, Hyprland config)

When `head = false`:
- Only terminal/CLI tools are installed
- No display server, window manager, or desktop environment

### Home-Manager Integration

Home-manager is integrated directly in NixOS configurations (not standalone). The `common.nix` module configures home-manager with:
- User: `aristide`
- Special args passed: `inputs`, `head`, `wallpaperPath`, `wallpaperFolder`
- Backup extension: `.bak` (prevents conflicts when switching configs)

## Host-Specific Details

### zola (Laptop - NVIDIA Hybrid Graphics)

**GPU Setup**: Intel iGPU + NVIDIA dGPU with Prime sync (not offload) for Wayland compatibility
- Uses proprietary NVIDIA drivers (`nvidia.open = false`)
- Extensive kernel params for Wayland/Hyprland stability
- Environment variables for NVIDIA + Wayland (`GBM_BACKEND=nvidia-drm`, `WLR_NO_HARDWARE_CURSORS=1`)
- CUDA cache configured (cuda-maintainers.cachix.org)

**Monitor config**: Currently has HDMI-A-1 (portrait) + VGA-1 external monitors. Laptop built-in display (likely `eDP-1`) is not yet configured in `/home/modules/hyprland.nix`.

### gary (Desktop - Old NVIDIA)

**GPU Setup**: NVIDIA GT 630 (Kepler/GK208) using nouveau open-source driver
- Proprietary NVIDIA 470 driver crashes Hyprland (initDRMFormats issue)
- Uses `nouveau.config=NvGrUseFW=0` kernel param (disables signed firmware loading for video engines)
- Blacklists all NVIDIA proprietary kernel modules
- Video driver: `modesetting` (uses nouveau DRM without legacy DDX driver)

### exupery (WSL2)

**Headless config** (`head = false`):
- Imports `nixos-wsl` module for WSL integration
- No bootloader, no NetworkManager (uses Windows host networking)
- SSH configured with empty password for local passwordless access (WSL-only, not for production)
- PAM configured with `nullok` option

## DMS (Dank Material Shell) Integration

DMS is a modern desktop shell/bar for Hyprland (replaces Waybar). Configuration:

1. **System-level**: DMS greeter enabled in `/modules/head.nix` with autologin
2. **User-level**: Full DMS config in `/home/head.nix` and `/home/dms-settings.nix`
3. **Settings file**: `dms-settings.nix` is a declarative export of DMS preferences (matugen theming, bar layout, widgets, animations)

**Key DMS features enabled**:
- Dynamic theming via matugen (generates colors from wallpaper)
- System monitoring (dgop), audio wavelength visualizer (cava)
- Calendar events (khal), clipboard paste (wtype)
- Bar config: Main bar on VGA-1 monitor with workspaces, system tray, media controls

**DMS keybinds** (defined in `/home/modules/hyprland.nix`):
- `Super+Space` - Spotlight launcher
- `Super+V` - Clipboard manager
- `Super+M` - Process list
- `Super+Tab` - Overview mode
- `Super+G` - Gemini special workspace (scratchpad with Chrome PWA + terminal)

## Custom PWA Applications

Chrome PWAs defined as desktop entries in `/home/head.nix`:
- **Gemini** (`gemini-chrome`): Google AI assistant at gemini.google.com
- **BandLab** (`bandlab-chrome`): Music production web app
- **Eraser** (`eraser-chrome`): Technical diagramming tool at app.eraser.io

All use `--user-data-dir=$HOME/.config/google-chrome-$(hostname)` for per-host profiles.

## Hyprland Configuration

**Monitor setup** (`/home/modules/hyprland.nix:68-72`):
- HDMI-A-1: 1920x1080@60, portrait mode (transform,1), scale 1.33
- VGA-1: 1920x1080@60, positioned right of HDMI, scale 1.33
- Fallback: `preferred,auto,1.33`

**Workspace assignments**:
- Workspace 0: HDMI-A-1 (left portrait monitor)
- Workspaces 1-5: VGA-1 (main monitor)
- Special workspace "gemini": Overlay scratchpad with custom gaps

**Keyboard**: French AZERTY layout (kb_layout = "fr")

**Input**: Flat acceleration profile with `force_no_accel = true` (1:1 mouse movement)

## Audio Production

**musnix** module enabled (`/modules/audio.nix`) for low-latency audio:
- ALSA sequencer enabled for MIDI
- Real-time kernel: disabled (can be enabled for ultra-low latency)
- No specific soundcard PCI ID pinned

**PipeWire config** (`/modules/head.nix`):
- PipeWire with JACK support for pro audio apps
- WirePlumber rule allows Chrome/Chromium full audio permissions (for BandLab PWA)

## Flake Inputs

- `nixpkgs`: nixos-unstable channel
- `home-manager`: User environment management
- `dms`: Dank Material Shell (stable branch)
- `danksearch`: Search tool integration
- `musnix`: Real-time audio optimization
- `nixos-wsl`: WSL2 support (exupery only)
- `synthwave84-yazi`: Yazi theme (non-flake input)

All inputs follow nixpkgs for consistency.

## Important Quirks

1. **NVIDIA on zola**: Requires extensive environment variables and kernel params. Never disable `WLR_NO_HARDWARE_CURSORS` or cursor will disappear.

2. **Nouveau on gary**: The `nouveau.config=NvGrUseFW=0` param is critical. Without it, firmware load failures cause stuck kworkers and phantom iowait.

3. **DMS settings**: `dms-settings.nix` is imported in `head.nix` as `settings = (import ./dms-settings.nix) // {}`. To override specific DMS options, use merge syntax in `head.nix`.

4. **Wallpaper theming**: DMS matugen generates system-wide color schemes from `/etc/nixos/src/wallpaper.jpg`. Changing this file requires rebuild.

5. **Cursor/VSCode**: The package is `code-cursor` (Cursor IDE, not standard VSCode). Extensions directory is mutable for easy extension installation.

6. **Docker vs Podman**: Both enabled. Docker has `dockerCompat = false` for podman to avoid conflicts.

7. **Git config**: Credential helper is `store` (plaintext). User is "Herzaristide" <aristide.pichereau@gmail.com>.

## Making Changes

When modifying this configuration:
1. Edit appropriate module file (don't edit `hardware-configuration.nix`)
2. Run `nixfmt` on changed files for consistent formatting
3. Test with `sudo nixos-rebuild switch --flake .#$(hostname)`
4. Commit changes with descriptive message (see git log for style)
5. If changing DMS settings, consider exporting live config: backup `~/.config/DankMaterialShell/settings.json` and update `dms-settings.nix`

For monitor configuration changes, edit `/home/modules/hyprland.nix` monitor array and workspace assignments together.
