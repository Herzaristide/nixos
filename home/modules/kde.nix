{
  pkgs,
  darkMode ? true,
  ...
}:

let
  # Slot Plasma Themes — GPL-3.0 by L4ki
  # Only the GTK theme and icon themes are used here (Hyprland, not KDE Plasma).
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
    iconTheme = {
      name = "Slot-Gray-Accent-Icons";
      # Populated at activation time by paletted (places/ recolored with accent).
      # Falls back to Slot-Gray-Dark-Icons via Inherits.
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

  # Icon themes — symlinked into ~/.local/share/icons/ so both GTK and Qt/KDE
  # find them without any cache generation step.
  xdg.dataFile."icons/Slot-Gray-Dark-Icons" = {
    source = "${slot-src}/Slot Icons Themes/Slot-Gray-Dark-Icons";
    force = true;
  };

  home.packages = with pkgs; [
    kdePackages.ark
  ];
}
