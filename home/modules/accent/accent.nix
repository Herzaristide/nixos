{
  pkgs,
  lib,
  accentDaemon,
  darkMode ? true,
  ...
}:

let
  # NixOS blue — used to seed accent.hex on first install only.
  defaultAccent = "#5277c3";
  defaultMode = if darkMode then "dark" else "light";
  defaultIconsTheme = "Arcanum-Accent";
in
{
  home.packages = [
    accentDaemon # provides both `paletted` and `palette` binaries
  ];

  # Templates installed read-only under ~/.config/accent/templates/.
  # paletted reads these and writes rendered output to
  # ~/.config/accent/fragments/ (color-only snippets imported by the
  # declarative Nix app configs) — except `kdeglobals.tmpl` which is
  # rendered as a full file (KDE/Qt has no include directive).
  #
  # Starship, micro, fastfetch are NOT listed: their configs are static
  # ANSI-only, declared in home/modules/shell/{starship,micro,fastfetch}.nix.
  xdg.configFile."accent/templates/alacritty-colors.toml.tmpl".source =
    ./templates/alacritty-colors.toml.tmpl;
  xdg.configFile."accent/templates/hyprland-colors.lua.tmpl".source =
    ./templates/hyprland-colors.lua.tmpl;
  xdg.configFile."accent/templates/gtk4-colors.css.tmpl".source = ./templates/gtk4-colors.css.tmpl;
  xdg.configFile."accent/templates/vesktop-colors.css.tmpl".source =
    ./templates/vesktop-colors.css.tmpl;
  xdg.configFile."accent/templates/kdeglobals.tmpl".source = ./templates/kdeglobals.tmpl;
  xdg.configFile."accent/templates/konsole.colorscheme.tmpl".source =
    ./templates/konsole.colorscheme.tmpl;
  xdg.configFile."accent/templates/tofi.config.tmpl".source = ./templates/tofi.config.tmpl;

  # quickCss.css for Vesktop is written directly by paletted (see templates.rs).
  # We don't declare it here because @import url("file://…") is dropped by
  # Vencord's inline <style> injection, so the full CSS must live at the target.

  # Remove settings.json.bak BEFORE home-manager checks for link-target collisions.
  # paletted replaces the nix-store symlink with a real file on first run; on the
  # next rebuild home-manager tries to back it up as settings.json.bak, but if that
  # file already exists from the previous run it aborts. Cleaning it here keeps the
  # path clear every time.
  home.activation.cleanVscodeBak = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    rm -f "$HOME/.config/Code/User/settings.json.bak"
  '';

  # Seed accent.hex / mode.txt on first install, then re-render all template
  # outputs via paletted --init.  Runs after linkGeneration so the nix-store
  # symlink for settings.json is in place before paletted overwrites it.
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
        mkdir -p "$accent_dir/fragments"
        mkdir -p "$HOME/.config/tofi"

        # Seed accent.hex with the current persisted color (or the palette default
        # on first install) so paletted --init has a source of truth to read.
        if [ ! -s "$accent_dir/accent.hex" ]; then
          printf '%s' "${defaultAccent}" > "$accent_dir/accent.hex"
        fi
        if [ ! -s "$accent_dir/mode.txt" ]; then
          printf '%s' "${defaultMode}" > "$accent_dir/mode.txt"
        fi
        # icons_theme.txt is always overwritten: it tracks the Nix declaration
        # (no runtime CLI to change it yet, so the rebuild value always wins).
        printf '%s' "${defaultIconsTheme}" > "$accent_dir/icons_theme.txt"

        # One-shot render: re-generates all template outputs without starting
        # the socket server.  --no-hyprctl because Hyprland may not be running
        # during activation.
        ${accentDaemon}/bin/paletted --init --no-hyprctl 2>&1 || true
      '';

  # ── systemd user service ──────────────────────────────────────────────────
  # Started automatically when the graphical session begins.
  # QuickShell, the `palette` CLI, and any future subscriber connect to
  # $XDG_RUNTIME_DIR/paletted.sock to read or change colors.
  systemd.user.services.paletted = {
    Unit = {
      Description = "Accent color and palette daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${accentDaemon}/bin/paletted";
      Restart = "on-failure";
      RestartSec = "2s";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
