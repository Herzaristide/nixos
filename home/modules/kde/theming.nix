{
  config,
  lib,
  pkgs,
  darkMode ? true,
  ...
}:

let
  # Slot Plasma Themes — GPL-3.0 by L4ki
  # Only the GTK theme is used here (Hyprland, not KDE Plasma).
  slot-src = pkgs.fetchFromGitHub {
    owner = "L4ki";
    repo = "Slot-Plasma-Themes";
    rev = "4dd93ad62cf47307d85e3a624eacba34578bf1fe";
    sha256 = "06pjizpkfd229mwa90a55888x15h5c9bvs59v12sh3ngyb4c4s1k";
  };

  slot-gtk-theme = pkgs.stdenv.mkDerivation {
    name = "slot-gtk-theme";
    src = slot-src;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/themes
      cp -r "Slot GTK Themes/Slot-Dark-GTK" $out/share/themes/Slot-Dark-GTK
    '';
  };

in
{
  # GTK theme — Slot Dark (Hyprland-compatible GTK theme by L4ki)
  gtk = {
    enable = true;
    theme = {
      # Slot only ships a dark variant; fall back to Breeze for light mode.
      name = if darkMode then "Slot-Dark-GTK" else "Breeze";
      package = if darkMode then slot-gtk-theme else pkgs.kdePackages.breeze-gtk;
    };
    font = {
      name = "JetBrains Mono";
      package = pkgs.jetbrains-mono;
      size = 11;
    };
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = darkMode;
    };
    gtk4 = {
      theme = null;
      extraConfig = {
        "gtk-application-prefer-dark-theme" = darkMode;
      };
      # Pulls in the libadwaita color tokens fragment rewritten by anna
      # on every accent change. The rest of the GTK4 config stays declarative.
      extraCss = ''
        @import url("file://${config.home.homeDirectory}/.config/accent/fragments/gtk4-colors.css");
      '';
    };
  };

  # Qt theming — Breeze (consistent with KDE apps like Dolphin)
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style = {
      name = "breeze";
      package = pkgs.kdePackages.breeze;
    };
  };

  # XDG menu spec entry point. Without it, kbuildsycoca6 never scans
  # share/applications, KApplicationTrader returns nothing, and Dolphin's
  # "Open with" dialog comes up empty. Distros that ship a full DE get this
  # file from plasma-workspace / gnome-menus / xfce4-session — none are
  # installed here, so drop the standard freedesktop.org boilerplate.
  xdg.configFile."menus/applications.menu".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN"
     "http://www.freedesktop.org/standards/menu-spec/1.0/menu.dtd">
    <Menu>
      <Name>Applications</Name>
      <Directory>Applications.directory</Directory>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <DefaultMergeDirs/>
      <Include>
        <All/>
      </Include>
      <Layout>
        <Merge type="menus"/>
        <Merge type="files"/>
      </Layout>
    </Menu>
  '';

  # Nix store paths change on every rebuild; the cached KService database keeps
  # pointing at gone-away .desktop files, leaving Dolphin's "Open with" dialog
  # empty.  Drop the stale caches and rebuild so the dialog repopulates.
  home.activation.rebuildKsycoca = lib.hm.dag.entryAfter [ "installPackages" ] ''
    run rm -f "$HOME/.cache/ksycoca6_"*
    run ${pkgs.kdePackages.kservice}/bin/kbuildsycoca6 --noincremental
  '';
}
