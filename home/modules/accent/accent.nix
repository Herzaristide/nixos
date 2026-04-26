{
  config,
  pkgs,
  lib,
  palette,
  palettes,
  darkMode ? true,
  ...
}:

let
  defaultAccent = "#${palette.base0D}";
  defaultMode = if darkMode then "dark" else "light";
  logoPath = ../../../src/nixos_logo.txt;

  # Generate a shell-sourceable env file from a palette attrset.
  # Each base16 key is uppercased: base00 → BASE00=rrggbb (no #).
  mkPaletteEnv = p: extra: ''
    BASE00=${p.base00}
    BASE01=${p.base01}
    BASE02=${p.base02}
    BASE03=${p.base03}
    BASE04=${p.base04}
    BASE05=${p.base05}
    BASE06=${p.base06}
    BASE07=${p.base07}
    BASE08=${p.base08}
    BASE09=${p.base09}
    BASE0A=${p.base0A}
    BASE0B=${p.base0B}
    BASE0C=${p.base0C}
    BASE0D=${p.base0D}
    BASE0E=${p.base0E}
    BASE0F=${p.base0F}
    ${extra}
  '';

  # Tools accent-sync calls. Prepended to PATH so the script works during
  # home-manager activation (where PATH is minimal) and inside Quickshell.
  runtimeDeps = with pkgs; [
    coreutils
    gawk
    gnused
    gnugrep
    procps # killall — SIGUSR1 to running kitty instances
    jq # merge accent into VSCode settings.json
  ];

  # Build accent-sync with the logo path and runtime PATH baked in.
  accentSyncSrc =
    let
      raw = builtins.readFile ./accent-sync.sh;
      withLogo = builtins.replaceStrings [ "@FASTFETCH_LOGO@" ] [ (toString logoPath) ] raw;
    in
    builtins.replaceStrings
      [ "#!/usr/bin/env bash\n" ]
      [
        "#!/usr/bin/env bash\nexport PATH=${lib.makeBinPath runtimeDeps}:\${PATH:-/run/current-system/sw/bin}\n"
      ]
      withLogo;

  accent-sync = pkgs.writeShellScriptBin "accent-sync" accentSyncSrc;
in
{
  home.packages = [ accent-sync ];

  # Palette env files — sourced by accent-sync at runtime to apply the right
  # base16 colors for the active mode.  Rebuilt on every nixos-rebuild so they
  # always reflect the current palette.nix values.
  xdg.configFile."accent/palette-dark.env".text =
    mkPaletteEnv palettes.dark "ICONS_THEME=breeze-dark";
  xdg.configFile."accent/palette-light.env".text = mkPaletteEnv palettes.light "ICONS_THEME=breeze";

  # Templates installed read-only under ~/.config/accent/templates/
  xdg.configFile."accent/templates/hyprland.conf.tmpl".source = ./templates/hyprland.conf.tmpl;
  xdg.configFile."accent/templates/starship.toml.tmpl".source = ./templates/starship.toml.tmpl;
  xdg.configFile."accent/templates/fastfetch-full.jsonc.tmpl".source =
    ./templates/fastfetch-full.jsonc.tmpl;
  xdg.configFile."accent/templates/fastfetch-logo.jsonc.tmpl".source =
    ./templates/fastfetch-logo.jsonc.tmpl;
  xdg.configFile."accent/templates/micro.tmpl".source = ./templates/micro.tmpl;
  xdg.configFile."accent/templates/wezterm-accent.lua.tmpl".source =
    ./templates/wezterm-accent.lua.tmpl;
  xdg.configFile."accent/templates/vesktop-quickcss.css.tmpl".source =
    ./templates/vesktop-quickcss.css.tmpl;
  xdg.configFile."accent/templates/gtk4.css.tmpl".source = ./templates/gtk4.css.tmpl;
  xdg.configFile."accent/templates/kdeglobals.tmpl".source = ./templates/kdeglobals.tmpl;

  # Make starship pick up the runtime-generated config (override programs.starship default).
  home.sessionVariables.STARSHIP_CONFIG = lib.mkForce "${config.home.homeDirectory}/.config/accent/starship.toml";

  # Remove settings.json.bak BEFORE home-manager checks for link-target collisions.
  # accent-sync replaces the nix-store symlink with a real file; on the next rebuild
  # home-manager tries to back it up to settings.json.bak, but if that file already
  # exists from the previous run it aborts. Cleaning it here (pre-checkLinkTargets)
  # keeps the path clear every time.
  home.activation.cleanVscodeBak = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f "$HOME/.config/Code/User/settings.json.bak"
  '';

  # Seed accent.hex on first activation, then regenerate every derived file.
  # Skip hyprctl during activation (might run on rebuild while no Hyprland is up).
  #
  # Source-of-truth: accent.hex + mode.txt
  #   - accent.hex: written by accent-sync (colorpicker, terminal, rebuild).
  #   - mode.txt:   dark|light; written by accent-sync on each run.
  #   - Both are read by Quickshell's FileView at runtime.
  #   - On first install these files don't exist yet; defaults are used.
  #   - On every rebuild accentSeed re-runs accent-sync with --mode matching
  #     config.darkMode so all derived files stay coherent.
  #
  # Must run AFTER vscodeProfiles, vscodeRemoteExtensions, AND linkGeneration
  # (linkGeneration symlinks managed files including settings.json; running
  # accent-sync last ensures it always wins).
  home.activation.accentSeed =
    lib.hm.dag.entryAfter
      [
        "writeBoundary"
        "vscodeProfiles"
        "vscodeRemoteExtensions"
        "linkGeneration"
      ]
      ''
        accent_dir="$HOME/.config/accent"
        mkdir -p "$accent_dir" "$HOME/.config/micro/colorschemes" "$HOME/.config/wezterm" "$HOME/.config/vesktop/settings"

        # Use the persisted color when available, fall back to the compiled default.
        if [ -s "$accent_dir/accent.hex" ]; then
          current="$(cat "$accent_dir/accent.hex")"
        else
          current="${defaultAccent}"
        fi

        for _attempt in 1 2 3; do
          if ${accent-sync}/bin/accent-sync "$current" --mode ${defaultMode} --no-hyprctl 2>&1; then
            break
          fi
          $VERBOSE_ECHO "accent-sync failed (attempt $_attempt), retrying in 1s..."
          sleep 1
        done || true
      '';
}
