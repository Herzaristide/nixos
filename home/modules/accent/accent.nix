{
  config,
  pkgs,
  lib,
  palette,
  ...
}:

let
  defaultAccent = "#${palette.base0D}";
  logoPath = ../../../src/nixos_logo.txt;

  # Tools accent-sync calls. Prepended to PATH so the script works during
  # home-manager activation (where PATH is minimal) and inside Quickshell.
  runtimeDeps = with pkgs; [
    coreutils
    gawk
    gnused
    gnugrep
    kitty
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

  # Templates installed read-only under ~/.config/accent/templates/
  xdg.configFile."accent/templates/hyprland.conf.tmpl".source = ./templates/hyprland.conf.tmpl;
  xdg.configFile."accent/templates/starship.toml.tmpl".source = ./templates/starship.toml.tmpl;
  xdg.configFile."accent/templates/fastfetch-full.jsonc.tmpl".source =
    ./templates/fastfetch-full.jsonc.tmpl;
  xdg.configFile."accent/templates/fastfetch-logo.jsonc.tmpl".source =
    ./templates/fastfetch-logo.jsonc.tmpl;
  xdg.configFile."accent/templates/micro.tmpl".source = ./templates/micro.tmpl;
  xdg.configFile."accent/templates/kitty-accent.conf.tmpl".source =
    ./templates/kitty-accent.conf.tmpl;

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
  home.activation.accentSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    accent_dir="$HOME/.config/accent"
    mkdir -p "$accent_dir" "$HOME/.config/micro/colorschemes" "$HOME/.config/kitty"
    if [ ! -s "$accent_dir/accent.hex" ]; then
      echo "${defaultAccent}" > "$accent_dir/accent.hex"
    fi
    current="$(cat "$accent_dir/accent.hex" 2>/dev/null || echo "${defaultAccent}")"
    # Retry up to 3 times in case of a transient issue (e.g. first-run template deploy).
    for _attempt in 1 2 3; do
      if ${accent-sync}/bin/accent-sync "$current" --no-hyprctl 2>&1; then
        break
      fi
      $VERBOSE_ECHO "accent-sync failed (attempt $_attempt), retrying in 1s..."
      sleep 1
    done || true
  '';
}
