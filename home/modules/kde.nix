{
  pkgs,
  lib,
  darkMode ? true,
  ...
}:

let
  # Goldy Plasma Themes — GPL-3.0 by L4ki
  # Only the GTK theme and icon themes are used here (Hyprland, not KDE Plasma).
  goldy-src = pkgs.fetchFromGitHub {
    owner = "L4ki";
    repo = "Goldy-Plasma-Themes";
    rev = "20e2b0eb3ed5f190496fc12ea027c63231d95ba0";
    sha256 = "1d4v6wf7nlgkryjlz39m6bzcnqw81vjj6vkjsmywqra4q97scp6s";
  };

  goldy-gtk-theme = pkgs.stdenv.mkDerivation {
    name = "goldy-gtk-theme";
    src = goldy-src;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/themes
      cp -r "Goldy GTK Themes" $out/share/themes/Goldy-Dark-GTK
    '';
  };

in
{
  # GTK theme — Goldy Dark (Hyprland-compatible GTK theme by L4ki)
  gtk = {
    enable = true;
    theme = {
      # Goldy only ships a dark variant; fall back to Breeze for light mode.
      name = if darkMode then "Goldy-Dark-GTK" else "Breeze";
      package = if darkMode then goldy-gtk-theme else pkgs.kdePackages.breeze-gtk;
    };
    iconTheme = {
      name = "Goldy-Accent-Icons";
      # Populated at activation time by accent-sync (places/ recolored with accent).
      # Falls back to Goldy-Dark-Icons via Inherits.
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

  # Dolphin declarative settings — uses kwriteconfig6 so Dolphin retains write access.
  home.activation.configureDolphin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file "$HOME/.config/dolphinrc" \
      --group PlacesPanel \
      --key HiddenEntries \
      "recentlyused:/,timeline:/today,timeline:/yesterday,timeline:/thismonth,timeline:/lastmonth"
    run ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 \
      --file "$HOME/.config/dolphinrc" \
      --group General \
      --key ShowRecentFiles \
      "false"
  '';

  # Icon themes — symlinked into ~/.local/share/icons/ so both GTK and Qt/KDE
  # find them without any cache generation step.
  xdg.dataFile."icons/Goldy-Dark-Icons".source = "${goldy-src}/Goldy Icons Themes/Goldy-Dark-Icons";

  home.packages = with pkgs; [
    kdePackages.dolphin
    kdePackages.kio-extras
    kdePackages.ark
    kdePackages.ffmpegthumbs
    kdePackages.kimageformats
  ];
}
