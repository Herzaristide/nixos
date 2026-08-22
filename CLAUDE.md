# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Flake-based NixOS configuration managing four hosts:

- **zola** (laptop): Intel + NVIDIA hybrid graphics, Prime **offload** mode, full GUI
- **gary** (desktop): AMD Ryzen 5 7600X + Radeon RX 7600 XT (ROCm/HIP), full GUI
- **kafka** (headless server): Intel + NVIDIA NVS 310 (nouveau), UEFI + systemd-boot, single NVMe SSD
- **exupery** (WSL2): headless development environment

## Build and Deployment

```bash
# Rebuild current system
sudo nixos-rebuild switch --flake .#$(hostname)

# Rebuild specific host
sudo nixos-rebuild switch --flake .#zola

# Update flake inputs
nix flake update

# Evaluate without building (catches eval errors)
nix flake check --no-build

# Format Nix files
nixfmt **/*.nix
```

Home-manager is integrated as a NixOS module, so `nixos-rebuild` updates both system and user configurations in one pass.

## Architecture

### Flake Inputs (`flake.nix`)

- `nixpkgs` — nixos-unstable channel
- `home-manager` — user environment, integrated as NixOS module
- `nixos-wsl` — WSL2 support (exupery only)
- `quickshell` — Wayland shell / bar runtime (replaces Waybar/DMS)
- `karenine` — the Quickshell interface (QML layout) **and** the `anna` engine (Rust: accent/palette theming + hardware stats). `github:Herzaristide/karenine`
- `explorer` — custom file manager (`github:Herzaristide/Explorer`)

### System modules (`/modules/`)

- `nixos.nix` — Nix-level settings (flakes, GC, `nix-ld`, `system.stateVersion`, build parallelism cap)
- `common.nix` — defines `head` / `primaryMonitor` / `darkMode` options; locale/keyboard FR; user `aristide` (immutable, hashed pwd); docker; ollama; wires home-manager into the system
- `network.nix` — NetworkManager + SSH (**key-only**: `PasswordAuthentication = false`, `KbdInteractiveAuthentication = false`, `PermitRootLogin = "no"`, `MaxAuthTries = 3`, `LoginGraceTime = 30`, no X11/agent forwarding) + firewall. **sshd is enabled unconditionally here, so it runs on all four hosts** — gary, zola, kafka *and* exupery (WSL) — and `services.openssh.openFirewall` (default `true`) opens port 22 on each. That is the only port opened anywhere; a host needing another opts in explicitly. (An earlier revision of this file claimed gary and zola set `services.openssh.enable = lib.mkForce false` and that kafka was the only reachable host — that `mkForce` has never existed in the tree. Corrected 2026-07-19. Note `home/modules/network/ssh.nix` declares gary as an SSH *target* at `192.168.1.138`, so a reachable gary is likely intentional.) Also disables Wake-on-LAN on every wired interface via the `disable-wake-on-lan` unit: a magic packet is unauthenticated, and since `ethtool -s … wol g` persists in the NIC across reboots, an earlier revision's WoL-enabling unit had to be actively reversed rather than merely deleted — the firmware may still enable it independently, cut it in the BIOS/UEFI for a complete disable.
- `power.nix` — UPower, logind suspend rules, USB wakeup
- `security.nix` — kernel sysctl hardening (kptr_restrict, dmesg_restrict, ptrace_scope, TCP/IP anti-spoofing), **no AppArmor** (removed 2026-07-19 — the upstream `pkgs.apparmor-profiles` that the NixOS module loads by default attach to `/usr/bin` and `/usr/lib` paths that don't exist on NixOS; verified on gary that 0 of the 202 loaded profiles referenced `/nix/store`, and 76 are `flags=(unconfined)` stubs anyway. Nothing depended on it: no systemd unit uses `AppArmorProfile=`, and rootless Docker reports `Security Options: seccomp` only. Re-enabling means hand-written profiles with store paths interpolated from Nix, plus a reboot — `enable` puts `apparmor` back in the kernel `lsm=` list), auditd (rules re-enabled 2026-07-19 after the `auditctl -R` / `-b` regression in the 4.1.2 snapshot; revert to `enable = false` if `audit-rules-nixos.service` fails again), fail2ban on sshd, LUKS auto-unlock via USB keyfile (`/dev/disk/by-partlabel/LUKSKEY`, 20s timeout then falls back to the passphrase prompt — note this trades some at-rest protection for convenience if the keyfile USB stick travels with the machine)
- `storage.nix` — mdadm RAID, fstrim, NTFS support, udisks2 auto-mount hardened with `noexec,nosuid,nodev`. The cross-host whitelist of external/internal mounts (`/mnt/maxtor`, `/mnt/samsung`, `/mnt/raid`) is currently commented out pending a disk changeover; only `/mnt/crucial` (uuid-pinned, `nofail`) is active
- `greetd.nix` — login screen: greetd + regreet, reskinned (CSS + wallpaper + clock widget) to match the Quickshell palette. Replaces the old getty-autologin flow — a password prompt is now required at every boot/logout. The greeter's compositor is **Hyprland**, not `cage`: cage exposes no output configuration (no rotation, no positioning), which left gary's upside-down DP-4 rendering inverted at login. The greeter reads the same monitor list as the session (`modules/monitors.nix`) and applies the same `renderDevice` GPU pinning. Its config is **Lua**, like the session (migrated 2026-08-22): hyprlang (`.conf`) is deprecated since 0.55 and 0.56 paints "You are using the .conf config format, support for which will be removed in Hyprland 0.57." across the login screen. Hyprland picks its parser from the file extension (`src/config/ConfigManager.cpp`), so the `.lua` filename passed to `--config` is what selects the Lua manager — there is no flag for it
- `monitors.nix` — the monitor list (output/mode/position/scale/transform), shared verbatim between the user's Hyprland session (`home/modules/hyprland/hyprland.nix`, Lua attrsets) and the greeter's Hyprland (`modules/greetd.nix`, rendered to `hl.monitor{}` calls). All hosts' outputs are listed together; each host only matches its own
- `head.nix` — GUI layer: declares the Hyprland session entry consumed by greetd, XDG portal (hyprland + kde), fonts (JetBrains Mono only), printing
- `audio.nix` — low-latency tweaks (`threadirqs`, ALSA seq modules, `@audio` PAM limits, plugin search paths), PipeWire (ALSA/JACK/Pulse), echo-cancel module, WirePlumber rule granting chromium `rwx` audio permissions (read/write/execute, deliberately not the `m` metadata bit) so the BandLab PWA can record — the rule matches on binary name, so it applies to every chromium process (all PWAs + regular browsing share the same binary), not just BandLab

### Home-manager config (`/home/`)

- `home.nix` — entry point. Imports headless modules (network/shell/code) unconditionally; adds the headful modules when `head = true`. Sets `EDITOR=micro`, `BROWSER=chromium`, `TERMINAL=alacritty`.
- `head.nix` — GUI user layer: dconf (color-scheme), cursor theme, fontconfig cache refresh, default mime apps, custom `file-explorer` desktop entry
- `modules/hyprland/hyprland.nix` — Hyprland config in **Lua** mode (`configType = "lua"`), keybinds, monitor setup, special workspaces. Has a lid-closed-layout helper script for zola.
- `modules/alacritty.nix` — terminal config
- `modules/hyprland/tofi.nix` — tofi application launcher (config rendue par anna, voir Theming)
- `modules/chromium.nix` — chromium package + PWA wrappers (`gemini-pwa`, `claude-pwa`, `bandlab-pwa`, `ytmusic-pwa`) sharing `~/.config/chromium` profile
- `modules/kde.nix` — minimal KDE/Qt theming (for xdg-portal-kde + appearance protocol)
- `modules/accent/accent.nix` — installs the anna engine (from the karenine flake) + its templates, systemd user service, and seed activation (see "Theming" below)
- `modules/shell/` — `fish`, `starship`, `fastfetch`, `micro`, `direnv`, `yazi`
- `modules/network/` — `git`, `ssh`
- `modules/code/` — Zed (`zed.nix`, headful only) + AI assistants (`ia/claude.nix`, `ia/copilot.nix`, `ia/mcp.nix`) + language runtimes

### Quickshell (`/quickshell/`)

QuickShell is the Wayland shell (bottom bar + side panel + Ollama chat + notes + hardware stats). Configured from `/quickshell/quickshell.nix` (home-manager). All QML files live in this directory and are installed read-only under `~/.config/quickshell/`. `shell.qml` is templated: `@PRIMARY_MONITOR@` is replaced with the value of the `primaryMonitor` option.

### Host configs (`/hosts/<hostname>/`)

- `configuration.nix` — host-specific imports, hostname, `head`, `primaryMonitor`, GPU/bootloader/power
- `hardware-configuration.nix` — generated by `nixos-generate-config`. **Do not hand-edit** unless reformatting or adding hardware-only concerns

## The `head` option

`head` (bool, default false) is defined in `modules/common.nix`. Hosts set it explicitly:

- `head = true` (gary, zola) — pulls in `modules/head.nix` and the headful home-manager modules (Hyprland, Quickshell, Walker, KDE/Qt theming, accent daemon, chromium, alacritty, etc.)
- `head = false` (exupery, kafka) — only CLI/server modules

`primaryMonitor` (string) is the Hyprland output that receives workspaces 1-5 and the Quickshell bar. Defaults to `HDMI-A-1`; zola overrides to `eDP-1`.

`darkMode` (bool, default true) drives the color scheme broadcast to dconf, GTK, Qt, and the accent daemon's seed defaults.

## Theming — anna engine (in the `karenine` flake)

The theming daemon now lives in the **`karenine`** repo as part of the unified Rust engine **`anna`** (`karenine/anna/`), exposed as `inputs.karenine.packages.x86_64-linux.anna` and re-exported here as `packages.x86_64-linux.anna`. It replaces the former local `accent-daemon` (binaries `paletted` + `palette`).

- Single binary `anna` dispatching on its first argument: `anna` (daemon), `anna init` (one-shot render), `anna set "#rrggbb"` / `anna mode` / `anna palette-color` / `anna get` / `anna watch` (CLI client). (`anna msi-rgb-watch` existe toujours en amont mais n'est plus câblé ici — la rétro-ingénierie du clavier MSI vit dans le projet `gpoc`, `~/ghub/gpoc`.)
- Runtime socket: `$XDG_RUNTIME_DIR/anna.sock`. State/fragments stay under `~/.config/accent/` (accent.hex, mode.txt, state.json, fragments/) — this path is still referenced by many app configs and gary's OpenRGB service
- Templates ship inside the anna package (`$out/share/anna/templates/`) and are installed read-only under `~/.config/accent/templates/`; rendered fragments land under `~/.config/accent/fragments/`
- Apps that support color includes (Hyprland, Alacritty, …) source the fragment directly from their declarative Nix config
- `kdeglobals.tmpl` is rendered as a full file (KDE/Qt has no include directive)
- Shell tools (starship/micro/fastfetch) are static ANSI-only and NOT templated
- The same engine serves hardware stats to Quickshell over the socket (`hwstats_watch`), replacing the shell-outs `HardwareStats.qml` used to spawn

To change the active accent at runtime: `anna set "#5277c3"`.

## Filesystem layout

All UEFI hosts share a single **disko** layout in `modules/disko.nix` (imported via `flake.nix`).

- UEFI hosts (zola, gary, kafka): GPT + ESP (FAT32, `/boot`, `fmask=0077`/`dmask=0077`) + LUKS2 (`allowDiscards=true`) → btrfs on `/dev/nvme0n1`
- WSL host (exupery): no disko, no bootloader
- btrfs subvolumes: `@` (`/`), `@home` (`/home`), `@nix` (`/nix`) — all persistent
- Mount options: `compress=zstd noatime space_cache=v2 discard=async ssd`
- To target a different disk on a future host, override `disko.devices.disk.main.device` with `lib.mkForce` in that host's `configuration.nix`.

LUKS passphrase is read from `/tmp/disko-luks-passphrase` during install — write the file before running disko, or pass it via `nixos-anywhere --extra-files`.

## Host-Specific Details

### zola (laptop — Intel + NVIDIA hybrid)

- NVIDIA proprietary driver (`open = false`), Prime **offload** (Intel iGPU default, NVIDIA on-demand via `nvidia-offload <cmd>`)
- Heavy Wayland-friendly env vars: `GBM_BACKEND=nvidia-drm`, `WLR_NO_HARDWARE_CURSORS=1`, `LIBVA_DRIVER_NAME=iHD` (Chrome video decode on Intel iGPU to avoid nvidia-vaapi bugs)
- `services.auto-cpufreq` + `thermald` + `powertop` for laptop power management
- `services.ollama.package = pkgs.ollama-cuda` with explicit `__NV_PRIME_RENDER_OFFLOAD` env so ollama systemd service picks the dGPU
- Cachix: `cuda-maintainers.cachix.org`
- Primary monitor: `eDP-1` (built-in)

### gary (desktop — AMD CPU + AMD GPU)

- AMD Ryzen 5 7600X (Zen 4 / Raphael, AM5, 6c/12t; amd-pstate EPP used automatically, no governor override)
- AMD Radeon RX 7600 XT (Navi 33 / RDNA3 / gfx1102) via `amdgpu`, loaded in initrd for seamless KMS. The 7600X also has a Raphael RDNA2 iGPU (gfx1036), also driven by amdgpu.
- ROCm stack for ML: `rocm-smi`, `rocminfo`, `clr`, `rocm-runtime`, `hipcc`
- `/opt/rocm` tmpfiles symlink to `pkgs.rocmPackages.clr` (PyTorch/TF default lookup path)
- **ROCm arch mapping**: RX 7600 XT is `gfx1102` but upstream rocBLAS ships kernels for the RDNA3 flagship `gfx1100` (not `gfx1102`). System-wide `HSA_OVERRIDE_GFX_VERSION=11.0.0` exposes the card as `gfx1100` so rocBLAS finds its Tensile kernels. No custom overlay → unmodified rocmPackages come straight from the Hydra binary cache (no 30-minute Tensile kernel regeneration on rebuild).
- `services.ollama.package = pkgs.ollama-rocm` (the explicit `HSA_OVERRIDE_GFX_VERSION` also covers other ROCm consumers on this host).
- `services.hardware.openrgb` (motherboard = amd) — RGB control for the ITE ARGB controller (case fans), Corsair mouse, RAM and GPU over SMBus
- Primary monitor: `DP-1` (Samsung C27R50x)

### kafka (headless server — Intel + NVS 310, UEFI)

- Intel CPU (`kvm-intel`, `hardware.cpu.intel.updateMicrocode`)
- NVIDIA NVS 310 (Fermi / GF119) — too old for the current proprietary driver; uses **in-tree nouveau** for a clean KMS console. No GUI stack.
- UEFI boot via systemd-boot (no GRUB)
- Single NVMe SSD on `/dev/nvme0n1`: shared layout from `modules/disko.nix` (GPT + ESP + LUKS2 + btrfs `@`/`@home`/`@nix`)

### exupery (WSL2)

- Imports `nixos-wsl.nixosModules.default`, `wsl.enable = true`
- No bootloader, NetworkManager disabled (uses Windows host networking)
- `SSL_CERT_FILE`/`NIX_SSL_CERT_FILE` point curl/wget/Nix at `/etc/ssl/certs/ca-bundle.crt`. **No TLS verification is disabled** — a prior `GIT_SSL_NO_VERIFY=true` / `NODE_TLS_REJECT_UNAUTHORIZED=0` pair was removed (2026-07-16): it blanket-disabled certificate checking for every git/Node process on the host instead of trusting a specific corporate CA. If a corporate proxy MITMs TLS again, add its root CA to the system trust store instead of disabling verification.

## Hyprland configuration notes

- Config language: **Lua** (`wayland.windowManager.hyprland.configType = "lua"`) — settings are emitted via `lib.generators` helpers, allowing `mkLuaInline` for native Lua calls
- **`hyprctl` speaks Lua too under the Lua parser** (fixed across the tree 2026-08-22): `hyprctl dispatch <name> <args>` is rejected ("dispatch in lua is a shorthand for hl.dispatch(...)") — write `hyprctl dispatch 'hl.dsp.dpms("on")'`, arguments in a table (`hl.dsp.focus({ monitor = "-1" })`, `hl.dsp.workspace.move({ workspace = "1", monitor = "HDMI-A-1" })`). `hyprctl keyword` is gone entirely ("keyword can't work with non-legacy parsers. Use eval.") — use `hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })'`. `hyprctl reload` still works, which is what the anna daemon uses to push accent changes. These calls fail *silently* from scripts and hypridle, so grep for `hyprctl dispatch`/`keyword` after any Hyprland bump
- Inside the config, a bind's action may be a Lua **function**, not just a dispatcher (`hl.bind(keys, function() hl.monitor{...} end)`) — that's how the lid-open bind reconfigures `eDP-1` without shelling out to `hyprctl`
- Keyboard: French AZERTY (`kb_layout = "fr"`)
- Input: flat acceleration + `force_no_accel = true` (1:1 mouse)
- `cursor.no_hardware_cursors = 1` (required for NVIDIA + Wayland)
- `decoration.active_opacity = 0.75 / inactive_opacity = 0.60`
- Special workspace `gemini` (scratchpad) auto-launches `gemini-pwa` via `on_created_empty`
- On zola, `hypr-closed-lid-layout` shell script moves workspaces 1-5 to `HDMI-A-1` and disables `eDP-1` when the lid is closed and the external monitor is present

## Audio (PipeWire)

- **No RT kernel, and no musnix** (removed 2026-07-19). The proprietary NVIDIA driver refuses to build against `CONFIG_PREEMPT_RT` (needs `IGNORE_PREEMPT_RT_PRESENCE=1`, unsupported upstream), which rules it out on zola; and PipeWire + rtkit + `threadirqs` already give 3-6 ms at a 128-256 frame buffer, well under the perception threshold for this (non-professional) usage. musnix also forced `powerManagement.cpuFreqGovernor = "performance"` **without `mkDefault`**, silently overriding zola's `powersave`. What it actually contributed is now inlined in `audio.nix`: `threadirqs`, `snd-seq`/`snd-rawmidi` (MIDI), `vm.swappiness = 10`, `@audio` PAM limits (rtprio/memlock), udev rules for `rtc0`/`hpet`/`cpu_dma_latency`, and the LV2/VST3/CLAP plugin search paths. If clicks ever appear, raise the buffer size first — an RT kernel is for cases where a dropout has an external consequence (live performance, motion control), not for home practice.
- PipeWire with ALSA + Pulse + **JACK** support (for pro audio apps)
- Echo cancellation module loaded (webrtc-aec) — exposes `echo-cancel-source` / `echo-cancel-sink` virtual nodes. Originally added to fix the voice-assistant feedback loop where piper TTS was being transcribed back by whisper.
- WirePlumber rule: chromium gets `default_permissions = "rwx"` (not `"all"`/`"rwxm"` — the `m` metadata bit is withheld) so the BandLab PWA can record audio
- Voice assistant tooling preinstalled: `whisper-cpp`, `piper-tts`, `sox`, `aubio`

## Chromium PWAs (`home/modules/chromium.nix`)

Four PWA wrappers, all sharing `~/.config/chromium`:

- `gemini-pwa` → gemini.google.com (also has a desktop entry; Super+G special workspace auto-launches it)
- `claude-pwa` → claude.ai
- `bandlab-pwa` → bandlab.com
- `ytmusic-pwa` → music.youtube.com (Super+Y)

All use `--enable-features=WebUIDarkMode --force-dark-mode`.

## User and security

- `users.mutableUsers = false` — `passwd`/`useradd` do nothing; create/change users only via Nix. The password hash is **not** in the Nix store: `aristide` uses `hashedPasswordFile = "/etc/passwd-aristide"`, a file placed out of band by `nixos-anywhere --extra-files` (an earlier revision of this file said the hashes were "baked into `modules/common.nix`" — they are not, and should not be: the store is world-readable. Corrected 2026-07-19). Root is locked outright (`hashedPassword = "!"`), so privilege escalation goes through `sudo`/wheel only, and `boot.loader.systemd-boot.editor = false` closes the `init=/bin/sh` bypass that would otherwise make the locked root moot.
- `aristide` is in groups: `networkmanager wheel video render audio storage greeter` (plus `kvm` on hosts importing `modules/android.nix`, for the emulator's KVM acceleration)
- **No `docker` group membership** — Docker runs rootless (`virtualisation.docker.rootless.enable`), so the daemon isn't running as root and group membership wouldn't grant a root-equivalent escape path anyway; deliberately left out
- Sudo NOPASSWD allowlist: `smartctl`, `dmidecode` (read-only hardware queries)
- Git identity commits as signed (`gpg.format = "ssh"`, `commit.gpgSign = true`, key `~/.ssh/siddhartha.pub`); credentials for HTTPS remotes go through `git-credential-manager` backed by GNOME Keyring/secretservice on headful hosts, or an in-memory cache on headless hosts — no plaintext credential store
- **GNOME Keyring** is the Secret Service store for `git-credential-manager` (HTTPS remotes), Zed, Copilot CLI and Chromium ("Chromium Safe Storage"). It is unlocked by `pam_gnome_keyring` at the greetd login, and started as a systemd user service from `home/head.nix` (`services.gnome-keyring`, `secrets` component only — ssh-agent lives in `home/modules/network/ssh.nix`). Do **not** rely on D-Bus activation alone: an activated daemon comes up locked and prompts for a password mid-session. Note the default keyring is `Default_Keyring`, unlocked by chaining from `login` — PAM only ever unlocks `login` directly

## Custom packages (`packages.x86_64-linux`)

- `anna` — re-export of `inputs.karenine.packages.x86_64-linux.anna` (the unified theming + hwstats engine; see "Theming")
- `iso` — bootable installer image (`hosts/iso/configuration.nix`) that embeds a read-only copy of this flake under `/etc/nixos` (via `environment.etc."nixos".source = inputs.self`). Build with `nix build .#iso`. Boots into a live NixOS with `nixos-install-here <hostname>` on the PATH, which runs disko (partition + LUKS + btrfs) from `/tmp/disko-luks-passphrase` (prompted interactively if absent) and then `nixos-install --flake`.
  - **Security note**: the ISO enables SSH with `PermitRootLogin = "yes"` and an empty root password, for convenience during headless/remote installs. Don't leave a booted installer connected to an untrusted network — anyone on the same segment can `ssh root@<ip>` with no password until the target host's own SSH config (key-only, see `network.nix`) takes over post-install.

## Important quirks

1. **NVIDIA on zola**: `WLR_NO_HARDWARE_CURSORS=1` is mandatory — disabling it kills the cursor on Wayland.
2. **ROCm on gary**: don't bring back a custom `gpuTargets` overlay — upstream rocBLAS already has `gfx1100` and we map the RX 7600 XT (Navi 33 / gfx1102) onto it via `HSA_OVERRIDE_GFX_VERSION=11.0.0`. Any overlay that touches `gpuTargets` diverges from the Hydra cache and triggers a ~30-minute Tensile kernel regeneration.
3. **Editors**: Zed is the primary editor (`home/modules/code/zed.nix`, headful only). VS Code was previously retired but is now back as a secondary editor via `home/modules/code/vscode.nix` (`programs.vscode`, headful only); both are wired by `home/home.nix`.
4. **Lua Hyprland config** — when editing `home/modules/hyprland/hyprland.nix`, remember it generates Lua, not the classic `hypr.conf` format. Use `mkLuaInline` for raw Lua, attribute sets for the rest.
5. **`primaryMonitor` is consumed by Quickshell**: changing the option value rewrites `~/.config/quickshell/shell.qml` via `builtins.replaceStrings`.
6. **mdadm warning at eval time** (`Neither MAILADDR nor PROGRAM has been set`) is benign — set `boot.swraid.mdadmConf` to silence it.

## Making changes

1. Edit the appropriate module file. Don't touch `hardware-configuration.nix` unless reformatting.
2. `nixfmt` the changed files.
3. `nix flake check --no-build` first to catch eval errors cheaply.
4. Then `sudo nixos-rebuild switch --flake .#$(hostname)`.
5. Commit with a descriptive message (see `git log` for style — short imperative subjects).

## Repo metadata

- Git user: `Herzaristide` &lt;aristide.pichereau@gmail.com&gt;
- Git credential helper: `git-credential-manager` (secretservice/GNOME Keyring on headful hosts, in-memory cache on headless hosts — see `home/modules/network/git.nix`)
- All `system.stateVersion` and `home.stateVersion` pinned to **25.11**
