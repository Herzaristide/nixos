# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Flake-based NixOS configuration managing five hosts:

- **bernanos** (laptop): Intel + NVIDIA hybrid graphics, Prime **offload** mode, full GUI (named `zola` until 2026-10-29 — renamed for the voice wake word: 3 syllables, no common French word close to it)
- **exupery** (Dell Latitude 7200 2-in-1): Intel UHD 620 only, full GUI like bernanos (`modules/head.nix`) + tablet features declared in its own `configuration.nix` (auto-rotation, on-screen keyboard, IR emitter)
- **gary** (headless dev server): AMD Ryzen 5 7600X + Radeon RX 7600 XT (ROCm/HIP), no GUI, holds no personal secrets; runs the autonomous Claude agents under the `claude` user
- **kafka** (headless dev server): Intel + NVIDIA NVS 310 (nouveau, no compute GPU), UEFI + systemd-boot, single NVMe SSD; runs Claude agents under `claude` like gary
- **wsl** (WSL2): headless development environment (named `exupery` until 2026-10-28 — the name now belongs to the Latitude)

## Build and Deployment

```bash
# Rebuild current system
sudo nixos-rebuild switch --flake .#$(hostname)

# Rebuild specific host
sudo nixos-rebuild switch --flake .#bernanos

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
- `nixos-wsl` — WSL2 support (wsl only)
- `quickshell` — Wayland shell / bar runtime (replaces Waybar/DMS)
- `karenine` — the Quickshell interface (QML layout) **and** the `anna` engine (Rust: accent/palette theming + hardware stats). `github:Herzaristide/karenine`
- `explorer` — custom file manager (`github:Herzaristide/Explorer`)
- `disko` — declarative partitioning; each host's layout is its own `hosts/<host>/disko.nix`
- `impermanence` — declarative `/home`, wired by `modules/impermanence.nix` on bernanos, exupery, gary and kafka

### System modules (`/modules/`)

- `nixos.nix` — Nix-level settings (flakes, GC, `nix-ld`, `system.stateVersion`, build parallelism cap)
- `common.nix` — defines `head` / `primaryMonitor` / `darkMode` options; locale/keyboard FR; user `aristide` (immutable, hashed pwd); docker; ollama (commented out — disabled on every host, see also the gary/bernanos configs); wires home-manager into the system
- `network.nix` — NetworkManager + SSH (**key-only**: `PasswordAuthentication = false`, `KbdInteractiveAuthentication = false`, `PermitRootLogin = "no"`, `MaxAuthTries = 3`, `LoginGraceTime = 30`, no X11/agent forwarding) + firewall. **sshd is enabled unconditionally here, so it runs on all five hosts** — gary, bernanos, exupery, kafka *and* wsl — and `services.openssh.openFirewall` (default `true`) opens port 22 on each. That is the only port opened anywhere; a host needing another opts in explicitly. (An earlier revision of this file claimed gary and bernanos set `services.openssh.enable = lib.mkForce false` and that kafka was the only reachable host — that `mkForce` has never existed in the tree. Corrected 2026-07-19. Note `home/modules/network/ssh.nix` declares gary as an SSH *target* at `192.168.1.138`, so a reachable gary is likely intentional.) Also disables Wake-on-LAN on every wired interface via the `disable-wake-on-lan` unit: a magic packet is unauthenticated, and since `ethtool -s … wol g` persists in the NIC across reboots, an earlier revision's WoL-enabling unit had to be actively reversed rather than merely deleted — the firmware may still enable it independently, cut it in the BIOS/UEFI for a complete disable. Also holds a **distraction blocklist** in `networking.hosts`: every YouTube domain *and*, since 2026-09-25, Twitch (`twitch.tv` + subdomains, plus the `static-cdn.jtvnw.net` / `usher.ttvnw.net` CDN and video hosts) resolve to `0.0.0.0`. It's `/etc/hosts`, so it only covers plain DNS — a browser doing DNS-over-HTTPS bypasses it.
- `power.nix` — UPower, logind suspend rules, USB wakeup
- `security.nix` — kernel sysctl hardening (kptr_restrict, dmesg_restrict, ptrace_scope, TCP/IP anti-spoofing), **no AppArmor** (removed 2026-07-19 — the upstream `pkgs.apparmor-profiles` that the NixOS module loads by default attach to `/usr/bin` and `/usr/lib` paths that don't exist on NixOS; verified on gary that 0 of the 202 loaded profiles referenced `/nix/store`, and 76 are `flags=(unconfined)` stubs anyway. Nothing depended on it: no systemd unit uses `AppArmorProfile=`, and rootless Docker reports `Security Options: seccomp` only. Re-enabling means hand-written profiles with store paths interpolated from Nix, plus a reboot — `enable` puts `apparmor` back in the kernel `lsm=` list), auditd (rules re-enabled 2026-07-19 after the `auditctl -R` / `-b` regression in the 4.1.2 snapshot; revert to `enable = false` if `audit-rules-nixos.service` fails again), fail2ban on sshd, LUKS auto-unlock via USB keyfile (`/dev/disk/by-partlabel/LUKSKEY`, 20s timeout then falls back to the passphrase prompt — note this trades some at-rest protection for convenience if the keyfile USB stick travels with the machine)
- `storage.nix` — mdadm RAID, fstrim, NTFS support, udisks2 auto-mount hardened with `noexec,nosuid,nodev`. The cross-host whitelist of external/internal mounts (`/mnt/maxtor`, `/mnt/samsung`, `/mnt/raid`) is currently commented out pending a disk changeover; only `/mnt/crucial` (uuid-pinned, `nofail`) is active
- `greetd.nix` — login screen: greetd + regreet, reskinned (CSS + clock widget, solid `#0d0d0d` background — no wallpaper anywhere since 2026-10-19) to match the Quickshell palette. Replaces the old getty-autologin flow — a password prompt is now required at every boot/logout. The greeter's compositor is **Hyprland**, not `cage`: cage exposes no output configuration (no rotation, no positioning), which left gary's upside-down DP-4 rendering inverted at login. The greeter reads the same monitor list as the session (`modules/monitors.nix`) and applies the same `renderDevice` GPU pinning. Its config is **Lua**, like the session (migrated 2026-08-22): hyprlang (`.conf`) is deprecated since 0.55 and 0.56 paints "You are using the .conf config format, support for which will be removed in Hyprland 0.57." across the login screen. Hyprland picks its parser from the file extension (`src/config/ConfigManager.cpp`), so the `.lua` filename passed to `--config` is what selects the Lua manager — there is no flag for it
- `monitors.nix` — the monitor list (output/mode/position/scale/transform), shared verbatim between the user's Hyprland session (`home/modules/hyprland/hyprland.nix`, Lua attrsets) and the greeter's Hyprland (`modules/greetd.nix`, rendered to `hl.monitor{}` calls). All hosts' outputs are listed together; each host only matches its own
- `head.nix` — GUI layer, **hardware-agnostic**: importing it sets `head = true` and pulls in `greetd.nix` + `nautilus.nix`; declares the Hyprland session entry consumed by greetd, XDG portal (hyprland + kde), fonts (JetBrains Mono only), and **howdy** face recognition (`sufficient`) enabled **only** for the Quickshell lock and `polkit-1` (`security.pam.howdy.enable = false` globally): greetd/login must take the password so `pam_gnome_keyring` can unlock the keyring, and sudo stays password-only since howdy can be fooled by a photo. The camera (`services.howdy.settings.video.device_path`) is hardware and set by each host: bernanos uses its RGB webcam (no IR camera), exupery its IR camera. Everything hardware (CPU, GPU, power, lid, firmware, monitors, `max-jobs`) lives in `hosts/<host>/configuration.nix`, duplicated between bernanos and exupery on purpose. **No gaming profile** — Steam, Proton-GE, gamescope, gamemode, MangoHud and the controller udev rules were removed on 2026-09-25 along with `modules/gaming.nix` and `home/modules/gaming.nix`; don't re-add them without asking. The Hyprland window rules for `steam`/`steam_app_*`/`gamescope` and `general.allow_tearing` went with them, as did the `.steam` / `.local/share/Steam` persistence entries (the shader caches `~/.cache/mesa_shader_cache` and `~/.cache/nvidia` stay — they serve every GPU app)
- `nautilus.nix` — bernanos and exupery: Nautilus is **the** file manager (Super+F, `inode/directory`, floating 1000×650 centred via a Hyprland window rule; Dolphin and a brief Nemo were dropped 2026-10-19) + gvfs + `nautilus-open-any-terminal` → Alacritty. Themed by the anna libadwaita fragment (`gtk4-colors.css`), which only works because the binary is wrapped with `--unset GTK_THEME`: the session-wide `GTK_THEME=Breeze-Dark` names a theme that isn't installed and makes libadwaita fall back to a generic grey. The wrapper also rewrites the two D-Bus `.service` files (`org.gnome.Nautilus`, `org.freedesktop.FileManager1`) that hardcode the original binary path. Sidebar bookmarks (`~/.config/gtk-3.0/bookmarks`) and `~/.local/share/nautilus` are persisted
- `impermanence.nix` — declarative `/home` on bernanos, exupery, gary and kafka: `@home` is wiped and recreated at every boot by an initrd unit, only the paths listed in `environment.persistence."/keep"` survive (details under "Filesystem layout"). Not imported by wsl
- `agents.nix` — gary and kafka (the dev servers): the `claude` user (uid 1001, home `/home/claude` with its own `environment.persistence."/keep".users.claude` list: `~/code` — where agents must clone —, `.claude`, `.claude.json`, `.config/gh`, docker rootless, direnv, rtk, uv and Hugging Face caches; groups `video`/`render` for ROCm, **no wheel/sudo**, key-only login, `linger`). Its home-manager config reuses the shell + `ia/common.nix` (Claude Code settings, LSPs, rtk, **all** MCP servers — the former `mcp-common.nix` split was dropped 2026-10-18) and runs `claude-rc@<repo>` Remote Control for every git repo cloned in `~/code` (rescanned each minute, `--spawn worktree`, session prefix `<host>-<repo>`). Agent rules live in its `~/.claude/CLAUDE.md` (ports 8000-8099 on `0.0.0.0`, PRs only, never merge). Limits: `user-1001.slice` MemoryHigh 65% / MemoryMax 80% of host RAM / CPUWeight 50; mangle/OUTPUT chain `agents-out` drops its traffic to LAN, tailnet and private ranges (v4 + v6), loopback and replies to inbound allowed. GPU wording and `HSA_OVERRIDE_GFX_VERSION` only where `nixpkgs.config.rocmSupport` is set (gary). One-time manual setup as `claude` on each host (`ssh claude@gary` / `ssh claude@kafka` — no `-A`: the key must never reach an agent session): `gh auth login` with a fine-grained token (chosen repos, Contents + Pull requests, no Workflows, never `nixos`), `claude auth login`, `claude remote-control` once per repo
- `audio.nix` — low-latency tweaks (`threadirqs`, ALSA seq modules, `@audio` PAM limits, plugin search paths), PipeWire (ALSA/JACK/Pulse), echo-cancel module, WirePlumber rule granting chromium `rwx` audio permissions (read/write/execute, deliberately not the `m` metadata bit) so the BandLab PWA can record — the rule matches on binary name, so it applies to every chromium process (all PWAs + regular browsing share the same binary), not just BandLab

### Home-manager config (`/home/`)

- `home.nix` — entry point. Imports headless modules (network/shell/code) unconditionally; adds the headful modules when `head = true`. Sets `EDITOR=micro`, `BROWSER=chromium`, `TERMINAL=alacritty`.
- `head.nix` — GUI user layer: dconf (color-scheme), cursor theme, fontconfig cache refresh, default mime apps, custom `file-explorer` desktop entry
- `modules/hyprland/hyprland.nix` — Hyprland config in **Lua** mode (`configType = "lua"`), keybinds, monitor setup and workspace rules (no special workspaces since 2026-10-16). Has a lid-closed-layout helper script for bernanos.
- `modules/alacritty.nix` — terminal config
- `modules/chromium.nix` — chromium package + PWA wrappers (`gemini-pwa`, `bandlab-pwa`, `ytmusic-pwa`) sharing `~/.config/chromium` profile. The former `claude-pwa` wrapper was dropped 2026-09-04 in favour of the `claude-desktop` package
- `modules/infinite-fusion.nix` — Pokémon Infinite Fusion (fangame, not in nixpkgs). `Game.exe` is a 64-bit Windows build of mkxp-z (also not in nixpkgs), so the `infinite-fusion` launcher runs it under `wineWow64Packages.stable`. The game is **not** in the store: the first launch shallow-clones `github:infinitefusion/infinitefusion-e18` (branch `releases` — the player branch, 6.8.2 as of 2026-07; `main` is stale since 2025-01 — several GB) into `~/.local/share/infinite-fusion/game` (in an alacritty window so progress is visible); the Wine prefix — which holds the saves, under `AppData/Roaming` — is `~/.local/share/infinite-fusion/prefix`. Both are persisted in `modules/impermanence.nix`. `infinite-fusion --update` pulls the latest commit (`reset --hard`, untracked sprites downloaded by the game are kept); `--performance` starts the upstream `InfiniteFusion-performance.exe` instead. Not a return of the gaming profile — no Steam/Proton/gamescope
- `modules/kde.nix` — minimal KDE/Qt theming (for xdg-portal-kde + appearance protocol)
- `modules/accent/accent.nix` — installs the anna engine (from the karenine flake) + its templates, systemd user service, and seed activation (see "Theming" below)
- `modules/shell/` — `fish`, `starship`, `fastfetch`, `micro`, `direnv`, `yazi`
- `modules/network/` — `git` (+ `gh` et `glab` : les CLI GitHub/GitLab vivent dans `git.nix` ; `programs.gh` a `gitCredentialHelper.enable = false` pour laisser git-credential-manager seul helper HTTPS, et `glab` est un simple `home.packages` — le module `programs.glab` a été supprimé upstream, issue #8066. Remplace `ghorg`, supprimé 2026-08-24), `ssh`
- `modules/code/` — Zed (`zed.nix`, headful only) + AI assistants (`ia/claude.nix`, `ia/copilot.nix`, `ia/mcp.nix`) + language runtimes

### Quickshell (`/quickshell/`)

QuickShell is the Wayland shell (bottom bar + side panel + Ollama chat + notes + hardware stats). Configured from `/quickshell/quickshell.nix` (home-manager). All QML files live in this directory and are installed read-only under `~/.config/quickshell/`. `shell.qml` is templated: `@PRIMARY_MONITOR@` is replaced with the value of the `primaryMonitor` option.

### Host configs (`/hosts/<hostname>/`)

- `configuration.nix` — host-specific imports, hostname, `head`, `primaryMonitor`, GPU/bootloader/power
- `hardware-configuration.nix` — generated by `nixos-generate-config`. **Do not hand-edit** unless reformatting or adding hardware-only concerns

## The `head` option

`head` (bool, default false) is defined in `modules/common.nix`. Hosts set it explicitly:

- `head = true` (bernanos, exupery) — pulls in `modules/head.nix` and the headful home-manager modules (Hyprland, Quickshell, Walker, KDE/Qt theming, accent daemon, chromium, alacritty, etc.)
- `head = false` (gary, kafka, wsl) — only CLI/server modules

`primaryMonitor` (string) is the Hyprland output that receives workspaces 1-5 and the Quickshell bar. Defaults to `HDMI-A-1`; bernanos and exupery override to `eDP-1`.

**Tablet (exupery)**: there is no `tablet` option (removed 2026-10-29) — everything tablet-specific lives in `hosts/exupery/configuration.nix`: `hardware.sensor.iio`, `linux-enable-ir-emitter`, and a `home-manager.users.aristide` block (merged with `home/home.nix`) adding two user services bound to `graphical-session.target` — `hypr-auto-rotate` (iio-sensor-proxy `monitor-sensor --accel` → `hyprctl eval` of `hl.monitor` + `input.touchdevice.transform`, using the eDP-1 entry of `modules/monitors.nix`; the rotation is also stored in `$XDG_RUNTIME_DIR/hypr-rotation` and re-applied from the Lua config, because anna's `hyprctl reload` would otherwise reset it) and `hypr-osk` (squeekboard — input-method-v2, so it only appears when a text field is focused; AZERTY via `org/gnome/desktop/input-sources`. A udev watcher sets `org/gnome/desktop/a11y/applications/screen-keyboard-enabled`, which squeekboard reads as "no physical keyboard", to false whenever a USB (the 7200's detachable keyboard) or Bluetooth device with `ID_INPUT_KEYBOARD=1` is present; mice exposing a keyboard interface go in `ignoredKeyboards`. nixpkgs' squeekboard needs a one-line Rust patch, applied there. Chromium gets `--enable-wayland-ime --wayland-text-input-version=3` on this host), plus the **hyprgrass** touch-gesture plugin (3-finger long press drags a window, 3-finger swipe down closes it). nixpkgs' hyprgrass doesn't build and targets Hyprland 0.55, so the host pins the upstream commit that `hyprpm.toml` maps to the running Hyprland version (with that commit's own `nix/wf-touch.nix`) — re-pin on every Hyprland bump, a plugin built against another version won't load — plus `workspace_swipe_touch`. iio-hyprland/rot8 are unusable here: they call `hyprctl keyword`.

`darkMode` (bool, default true) drives the color scheme broadcast to dconf, GTK, Qt, and the accent daemon's seed defaults.

## Theming — anna engine (in the `karenine` flake)

The theming daemon now lives in the **`karenine`** repo as part of the unified Rust engine **`anna`** (`karenine/anna/`), exposed as `inputs.karenine.packages.x86_64-linux.anna` and re-exported here as `packages.x86_64-linux.anna`. It replaces the former local `accent-daemon` (binaries `paletted` + `palette`).

- Single binary `anna` dispatching on its first argument: `anna` (daemon), `anna init` (one-shot render), `anna set "#rrggbb"` / `anna mode` / `anna palette-color` / `anna get` / `anna watch` (CLI client). (`anna msi-rgb-watch` existe toujours en amont mais n'est plus câblé ici — la rétro-ingénierie du clavier MSI vit dans le projet `gpoc`, `~/ghub/gpoc`.)
- Runtime socket: `$XDG_RUNTIME_DIR/anna.sock`. State/fragments stay under `~/.config/accent/` (accent.hex, mode.txt, state.json, fragments/) — this path is still referenced by many app configs and gary's OpenRGB service
- Templates ship inside the anna package (`$out/share/anna/templates/`) and are installed read-only under `~/.config/accent/templates/`; rendered fragments land under `~/.config/accent/fragments/`
- Apps that support color includes (Hyprland, Alacritty, …) source the fragment directly from their declarative Nix config
- `kdeglobals.tmpl` is rendered as a full file (KDE/Qt has no include directive)
- **Icon theme `Reversal-Accent`** (since 2026-10-20): anna (`anna/src/icons.rs`) regenerates it under `~/.local/share/icons/` at startup and on every accent/mode change, from `pkgs.reversal-icon-theme` (store path baked into its wrapper as `ANNA_ICON_SOURCE`). Only `apps/scalable` + `places/scalable` are rewritten ("mono": accent hue, original lightness; Firefox/Krita kept); every other context is a symlink to the store, so nothing is copied and nothing needs persisting. GTK gets the name from `gtk.iconTheme`, Qt from kdeglobals (`icons_theme.txt`). Qt caches theme icons for the life of a process, so anna also writes `$XDG_RUNTIME_DIR/anna-icons.json` (name → recoloured file + revision) and karenine loads those icons through `Theme.icon()` as `file://…?rev=` URLs — use `Theme.icon`, not `Quickshell.iconPath`, in karenine QML
- Shell tools (starship/micro/fastfetch) are static ANSI-only and NOT templated
- The same engine serves hardware stats to Quickshell over the socket (`hwstats_watch`), replacing the shell-outs `HardwareStats.qml` used to spawn

To change the active accent at runtime: `anna set "#5277c3"`.

## Filesystem layout

Each UEFI host has **its own** disko file, wired in `flake.nix`: `hosts/bernanos/disko.nix`, `hosts/gary/disko.nix`, `hosts/kafka/disko.nix`. bernanos's and gary's are byte-identical; kafka's differs (ESP on a USB stick, see its section). The pre-split shared copy `modules/disko.nix` was deleted on 2026-08-24 — imported by nobody and missing `@keep`; a merge from a stale remote branch had resurrected it along with ~56 other long-deleted files. (Corrected 2026-08-24 — this file previously described the shared-layout arrangement, which the per-host split replaced.)

- bernanos / gary: GPT + ESP (FAT32, `/boot`, `fmask=0077`/`dmask=0077`) + LUKS2 (`allowDiscards=true`) → btrfs on `/dev/nvme0n1`
- exupery: own copy of bernanos's layout (`hosts/exupery/disko.nix`)
- WSL host (wsl): no disko, no bootloader
- btrfs subvolumes: `@` (`/`), `@home` (`/home`), `@nix` (`/nix`), plus `@keep` on bernanos/gary/kafka
- Mount options: `compress=zstd noatime space_cache=v2 discard=async ssd`
- To target a different disk on a future host, override `disko.devices.disk.main.device` with `lib.mkForce` in that host's `configuration.nix`.

LUKS passphrase is read from `/tmp/disko-luks-passphrase` during install — write the file before running disko, or pass it via `nixos-anywhere --extra-files`.

### Impermanence — `/home` only, bernanos, exupery, gary and kafka

`modules/impermanence.nix` is imported by **bernanos, exupery, gary and kafka** (`hosts/<host>/configuration.nix`; kafka since 2026-10-18, exupery since its creation on 2026-10-28). wsl doesn't import it and is fully persistent — WSL couldn't run it anyway: its filesystem comes from the Windows-side image, there is no LUKS, no btrfs subvolume, and no systemd initrd to roll anything back in.

- **Only `@home` is wiped.** The initrd unit `rollback-home` recreates an empty `@home` at every boot; `@` (`/`) and `@nix` are never touched. So `/var/lib/nixos`, `/var/lib/*` and everything else under `/` survives — which is why `enableWarnings = false` on `environment.persistence` is correct here rather than a papered-over bug (the module's warning assumes an ephemeral root).
- What survives lives on the `@keep` subvolume, mounted `neededForBoot` at `/keep/home`, and is listed file-by-file / directory-by-directory under `environment.persistence."/keep".users.aristide`. **Anything not in that list is gone at the next boot.**
- The list is split by role: a shared part (shell history, `.claude`, `.ssh` for `known_hosts`, docker rootless, uv, direnv, shader cache), a `config.head` part (bernanos: secrets, GUI app state, personal data dirs) and a `!config.head` part (dev servers gary and kafka: `~/code` only — the one place to clone repos, since impermanence cannot persist a home root). `claude` has its own list in `modules/agents.nix`. The servers therefore keep no secret and no stray file across reboots by construction.
- **Home layout** (`home/xdg.nix`, same on every host, renamed 2026-10-22 — formerly `ciph3r`/`d3pot`/`f3tch`/`sc0re`/`sh3lf`/`v4ult`/`f0rge`): one level, four lowercase letters — `code` (repos, XDG projects), `docs` (documents, Ajar books, scores), `drop` (downloads), `lens` (XDG pictures **and** videos), `tune` (XDG music: audio recordings). Obsidian was removed the same day; `docs` is not a vault.
- `@keep` is the old `@home` renamed, so `aristide/` already lands on `/keep/home/aristide` — that's what made the initial migration a rename rather than a file copy. The module's header still points at `scripts/impermanence-migrate.sh`, which **no longer exists** in the tree (dropped once the migration was done; recover it from git history if a new host ever needs it).
- **Wipes are archived, not deleted**: the old `@home` is moved to `old_roots/<timestamp>` and only purged after `retentionDays = 30`. A path forgotten in the list stays recoverable for a month.
- **Guard rail**: if `@keep` is absent, `rollback-home` logs and exits without touching anything, so adding the module to a host that hasn't been migrated destroys nothing.
- Extending impermanence to `/` is noted in the module as a possible "étape 1" but is **not** done today.

## Host-Specific Details

### bernanos (laptop — Intel + NVIDIA hybrid)

- NVIDIA proprietary driver (`open = false`), Prime **offload** (Intel iGPU default, NVIDIA on-demand via `nvidia-offload <cmd>`)
- Heavy Wayland-friendly env vars: `GBM_BACKEND=nvidia-drm`, `WLR_NO_HARDWARE_CURSORS=1`, `LIBVA_DRIVER_NAME=iHD` (Chrome video decode on Intel iGPU to avoid nvidia-vaapi bugs)
- `services.auto-cpufreq` + `thermald` + `powertop` for laptop power management
- **CUDA à la carte, no global `cudaSupport`**: only Blender is built with CUDA/OptiX, via an overlay in `hosts/bernanos/configuration.nix` (`blender.override { cudaSupport = true; }`), with `cudaCapabilities = [ "8.6" ]` (RTX 3070 Mobile only). The global flag also rebuilt openusd, suitesparse and ceres-solver for no real gain. The same overlay wraps `bin/blender` (`symlinkJoin` + `wrapProgram`) with the PRIME offload variables, so Blender always runs on the RTX — changing the wrapper doesn't rebuild Blender. The CUDA Blender recompiles locally on every unstable bump (hence `max-jobs = 1`). **Don't take GUI apps from a frozen nixpkgs**: a frozen `nixpkgs-cuda` input (removed 2026-10-17) made Blender quit at startup with `EGL Error` once the system Mesa was built against a newer glibc than the app — Mesa is dlopened from `/run/opengl-driver` into the app's process. ollama is disabled; if re-enabled, use `pkgs.ollama-cuda` plus the commented `__NV_PRIME_RENDER_OFFLOAD` env
- No CUDA binary cache: `cuda-maintainers.cachix.org` was shut down (HTTP 401) and removed 2026-09-30; `cache.nixos-cuda.org` did not carry these builds either. CUDA packages therefore rebuild locally on nixpkgs bumps that touch them
- Primary monitor: `eDP-1` (built-in)

### gary (desktop — AMD CPU + AMD GPU)

- AMD Ryzen 5 7600X (Zen 4 / Raphael, AM5, 6c/12t; amd-pstate EPP used automatically, no governor override)
- AMD Radeon RX 7600 XT (Navi 33 / RDNA3 / gfx1102) via `amdgpu`, loaded in initrd for seamless KMS. The 7600X also has a Raphael RDNA2 iGPU (gfx1036), also driven by amdgpu.
- ROCm stack for ML: `rocm-smi`, `rocminfo`, `clr`, `rocm-runtime`, `hipcc`
- `/opt/rocm` tmpfiles symlink to `pkgs.rocmPackages.clr` (PyTorch/TF default lookup path)
- **ROCm arch mapping**: RX 7600 XT is `gfx1102` but upstream rocBLAS ships kernels for the RDNA3 flagship `gfx1100` (not `gfx1102`). System-wide `HSA_OVERRIDE_GFX_VERSION=11.0.0` exposes the card as `gfx1100` so rocBLAS finds its Tensile kernels. No custom overlay → unmodified rocmPackages come straight from the Hydra binary cache (no 30-minute Tensile kernel regeneration on rebuild).
- ollama is disabled (commented out); `HSA_OVERRIDE_GFX_VERSION` covers every ROCm consumer on this host.
- `services.hardware.openrgb` (motherboard = amd) — RGB control for the ITE ARGB controller (case fans), Corsair mouse, RAM and GPU over SMBus
- **Dev server since 2026-10-18**: bernanos is the only workstation (identity, keys, vault, browsers, accounts); gary was purged of every personal secret and file (moved to `/mnt/crucial/gary-2026-10-18/`, still to be sorted) and only carries project clones and Claude instances. Two Unix accounts: `aristide` = admin (wheel) + supervised work, projects cloned in `~/code` (git over SSH with the key forwarded from bernanos, `ssh -A gary` — never stored on gary); `claude` = unsupervised agents (`modules/agents.nix`). The former microVMs (`modules/devbox.nix`, microvm.nix input) were removed the same day: nearly every project needs the GPU, which a VM could only get by passthrough (card taken from the host, VM RAM pinned).

### kafka (headless server — Intel + NVS 310, UEFI)

- Intel CPU (`kvm-intel`, `hardware.cpu.intel.updateMicrocode`)
- NVIDIA NVS 310 (Fermi / GF119) — too old for the current proprietary driver; uses **in-tree nouveau** for a clean KMS console. No GUI stack.
- UEFI boot via systemd-boot (no GRUB), but the T3610 firmware has no NVMe driver: the **ESP lives on a USB stick** (FAT label `KAFKABOOT`, pinned by `/dev/disk/by-id/usb-…`) acting as a boot relay — the firmware boots the stick, whose kernel carries the NVMe driver, unlocks the LUKS volume and mounts the btrfs root. The stick must be plugged in during `nixos-rebuild`, or systemd-boot can't write its entries (`/boot` is `nofail`).
- Single NVMe SSD on `/dev/nvme0n1`, carrying **only** LUKS2 + btrfs (`@`/`@home`/`@nix`, no ESP) — own layout in `hosts/kafka/disko.nix`
- Impermanence since 2026-10-18 (same server list as gary). Migration, **before** the first switch: `sudo mount -o subvolid=5 /dev/mapper/cryptroot /mnt && sudo btrfs subvolume snapshot /mnt/@home /mnt/@keep && sudo umount /mnt` — without `@keep`, the `neededForBoot` mount of `/keep/home` fails. The first boot archives the old `@home` to `old_roots/` (30 days), and everything in aristide's home outside the list (`~/code` + tooling) is gone from the live system — which is also how kafka gets purged of personal files. Move anything worth keeping into `~/code` or off the machine first
- Dev server like gary since 2026-10-18: imports `modules/agents.nix` (`claude` user, no GPU)

### exupery (Dell Latitude 7200 2-in-1)

- Intel Core i5-8365U (Whiskey Lake, 4c/8t), 16 GB, Intel UHD 620 only (`LIBVA_DRIVER_NAME=iHD`, no NVIDIA variables); 12.3" 1920×1280 touchscreen on `eDP-1`, accelerometer via the Intel Sensor Hub (`hardware.sensor.iio.enable`)
- Same module set as bernanos (impermanence included, `head.nix`), with its own hardware block (duplicated from bernanos on purpose): same disko layout on `/dev/nvme0n1`; `auto-cpufreq` capped at 1.6 GHz / no turbo on battery, 4.1 GHz on AC; `fwupd`; lid → suspend; `max-jobs = 1`
- **howdy**: configured in `modules/head.nix`; here it uses the IR camera, switched on by `linux-enable-ir-emitter` (exupery only, `device = "video2"`). One-time setup: `sudo linux-enable-ir-emitter configure`, then `sudo howdy add`
- No `hardware-configuration.nix` (like bernanos): `modules/kernel.nix` + `not-detected.nix` cover it

### wsl (WSL2)

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
- Windows are fully opaque: no `active_opacity` / `inactive_opacity` in `decoration` (Hyprland's 1.0 default) — light transparency was tried and dropped again on 2026-10-19
- On bernanos, `hypr-closed-lid-layout` shell script moves workspaces 1-5 to `HDMI-A-1` and disables `eDP-1` when the lid is closed and the external monitor is present

## Audio (PipeWire)

- **No RT kernel, and no musnix** (removed 2026-07-19). The proprietary NVIDIA driver refuses to build against `CONFIG_PREEMPT_RT` (needs `IGNORE_PREEMPT_RT_PRESENCE=1`, unsupported upstream), which rules it out on bernanos; and PipeWire + rtkit + `threadirqs` already give 3-6 ms at a 128-256 frame buffer, well under the perception threshold for this (non-professional) usage. musnix also forced `powerManagement.cpuFreqGovernor = "performance"` **without `mkDefault`**, silently overriding bernanos's `powersave`. What it actually contributed is now inlined in `audio.nix`: `threadirqs`, `snd-seq`/`snd-rawmidi` (MIDI), `vm.swappiness = 10`, `@audio` PAM limits (rtprio/memlock), udev rules for `rtc0`/`hpet`/`cpu_dma_latency`, and the LV2/VST3/CLAP plugin search paths. If clicks ever appear, raise the buffer size first — an RT kernel is for cases where a dropout has an external consequence (live performance, motion control), not for home practice.
- PipeWire with ALSA + Pulse + **JACK** support (for pro audio apps)
- Echo cancellation module (webrtc-aec, `monitor.mode`) — exposes `echo-cancel-source`: the default mic minus what the default sink plays (read from its monitor, so playback is not rerouted or delayed). Only anna listens to it (wake word + dictation); the default mic stays raw, no AGC or noise suppression.
- WirePlumber rule: chromium gets `default_permissions = "rwx"` (not `"all"`/`"rwxm"` — the `m` metadata bit is withheld) so the BandLab PWA can record audio
- Voice assistant tooling preinstalled: `whisper-cpp`, `piper-tts`, `sox`, `aubio`

## Chromium PWAs (`home/modules/chromium.nix`)

Three PWA wrappers, all sharing `~/.config/chromium`:

- `gemini-pwa` → gemini.google.com (also has a desktop entry)
- `bandlab-pwa` → bandlab.com
- `ytmusic-pwa` → music.youtube.com (Super+Y)

All use `--enable-features=WebUIDarkMode --force-dark-mode`.

## User and security

- `users.mutableUsers = false` — `passwd`/`useradd` do nothing; create/change users only via Nix. The password hash is **not** in the Nix store: `aristide` uses `hashedPasswordFile = "/etc/passwd-aristide"`, a file placed out of band by `nixos-anywhere --extra-files` (an earlier revision of this file said the hashes were "baked into `modules/common.nix`" — they are not, and should not be: the store is world-readable. Corrected 2026-07-19). Root is locked outright (`hashedPassword = "!"`), so privilege escalation goes through `sudo`/wheel only, and `boot.loader.systemd-boot.editor = false` closes the `init=/bin/sh` bypass that would otherwise make the locked root moot.
- `aristide` is in groups: `networkmanager wheel video render audio storage greeter` (plus `kvm` on hosts importing `modules/android.nix`, for the emulator's KVM acceleration)
- **No `docker` group membership** — Docker runs rootless (`virtualisation.docker.rootless.enable`), so the daemon isn't running as root and group membership wouldn't grant a root-equivalent escape path anyway; deliberately left out
- Sudo NOPASSWD allowlist: `smartctl`, `dmidecode` (read-only hardware queries)
- Git commits are **not signed** (signing removed 2026-10-17: `~/.ssh/siddhartha` stays out of the dev VMs, and signing there would attribute Claude's commits to the user); credentials for HTTPS remotes go through `git-credential-manager` backed by GNOME Keyring/secretservice on headful hosts, or an in-memory cache on headless hosts — no plaintext credential store
- **GNOME Keyring** is the Secret Service store for `git-credential-manager` (HTTPS remotes), Zed, Copilot CLI and Chromium ("Chromium Safe Storage"). It is unlocked by `pam_gnome_keyring` at the greetd login, and started as a systemd user service from `home/head.nix` (`services.gnome-keyring`, `secrets` component only — ssh-agent lives in `home/modules/network/ssh.nix`). Do **not** rely on D-Bus activation alone: an activated daemon comes up locked and prompts for a password mid-session. Note the default keyring is `Default_Keyring`, unlocked by chaining from `login` — PAM only ever unlocks `login` directly

## Custom packages (`packages.x86_64-linux`)

- `anna` — re-export of `inputs.karenine.packages.x86_64-linux.anna` (the unified theming + hwstats engine; see "Theming")
- `claude-desktop` — repackaging of Anthropic's official `.deb` (`pkgs/claude-desktop/default.nix`), since the app is not in nixpkgs (PR #537215 still open). Unpacks the deb from `downloads.claude.ai` and autoPatchelfs the bundled Electron 42; `chrome-sandbox` is removed so Electron falls back to the namespace sandbox. `withCowork` (default `true`) adds qemu + OVMF for the Cowork micro-VM — that flag alone is 3 GiB of the 4.1 GiB closure. Bump by hand: read the newest version + SHA256 from the apt `Packages.gz` (command in the file header), then `nix hash convert`. Wired as a headful home-manager module (`home/modules/code/ia/claude-desktop.nix`); its state lives in `~/.config/Claude`, persisted in `modules/impermanence.nix`. Replaced the `claude-pwa` Chromium wrapper on 2026-09-04. It used to back a `special:claude` scratchpad (Super+C), removed 2026-10-16. Note the app is single-instance (`SingleMainWindow`), so relaunching it focuses the existing window instead of opening a second one — unlike the old `chromium --app` wrapper. **Login flow**: claude.ai ends its OAuth round-trip on a `claude://` redirect, so two pieces must stay in place — `x-scheme-handler/claude` in `home/head.nix` (`xdg.mimeApps`), and `AutoLaunchProtocolsFromOrigins` in the Chromium managed policy (`home/modules/chromium.nix`), which skips the "Open Claude?" dialog for the claude.ai/claude.com origins. The app itself cannot register the handler: it tries to write `~/.config/mimeapps.list`, which home-manager owns read-only (harmless ERROR line at every launch). **Do not use the `${NIXOS_OZONE_WL:+…}` idiom in the wrapper**: `wrapGAppsHook3` emits a *binary* wrapper, which expands nothing, so the literal string reached Chromium as the first non-`-` argument — i.e. as the URL to open — and swallowed the `claude://` deep link, leaving the login silently stuck. Plain `--ozone-platform-hint=auto` covers both Wayland and X11 without any shell test.

## Important quirks

1. **NVIDIA on bernanos**: `WLR_NO_HARDWARE_CURSORS=1` is mandatory — disabling it kills the cursor on Wayland.
2. **ROCm on gary**: don't bring back a custom `gpuTargets` overlay — upstream rocBLAS already has `gfx1100` and we map the RX 7600 XT (Navi 33 / gfx1102) onto it via `HSA_OVERRIDE_GFX_VERSION=11.0.0`. Any overlay that touches `gpuTargets` diverges from the Hydra cache and triggers a ~30-minute Tensile kernel regeneration.
3. **Editors**: Zed is the only editor (`home/modules/code/zed.nix`, headful only, wired by `home/home.nix`). VS Code was briefly back as a secondary editor (`home/modules/code/vscode.nix`) but was removed again on 2026-09-04 — don't re-add it without asking.
4. **Lua Hyprland config** — when editing `home/modules/hyprland/hyprland.nix`, remember it generates Lua, not the classic `hypr.conf` format. Use `mkLuaInline` for raw Lua, attribute sets for the rest.
5. **`primaryMonitor` is consumed by Quickshell**: changing the option value rewrites `~/.config/quickshell/shell.qml` via `builtins.replaceStrings`.
6. **New home state on bernanos/gary must be declared** — anything a tool writes under `~` that has to outlive a reboot (a new credential store, cache, or app state directory) needs an entry in `environment.persistence."/keep".users.aristide` in `modules/impermanence.nix`, or it is wiped at the next boot. Home-manager-managed files are fine (regenerated on activation); runtime-written state is not. If something disappeared, it is still in `old_roots/<timestamp>` for 30 days — that lives at the btrfs top level, which nothing mounts at runtime, so reach it with `sudo mount -t btrfs -o subvolid=5 /dev/mapper/cryptroot /mnt/…`.
7. **mdadm warning at eval time** (`Neither MAILADDR nor PROGRAM has been set`) is benign — set `boot.swraid.mdadmConf` to silence it.

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
