{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  # Disable the experimental Fontations (Rust/Skrifa) font rendering backend.
  # NixOS 26.05 enables FC_FONTATIONS=1 by default, but this causes white/blank
  # glyph squares in GTK popup windows (file dialogs, git popups, etc.).
  # Force the stable FreeType backend instead.
  environment.variables.FC_FONTATIONS = "0";

  # Run Electron/Chromium apps in native Wayland mode. Required so Chromium uses
  # wl_data_device for drag-and-drop: without it Chromium runs under XWayland and
  # cross-protocol DnD from native Wayland apps (Dolphin) silently fails.
  environment.variables.NIXOS_OZONE_WL = "1";

  # dconf: required for GTK app settings and GNOME applications
  programs.dconf.enable = true;

  # GNOME Keyring (Secret Service daemon) for git-credential-manager `secretservice` store.
  # PAM hook unlocks the keyring at login with the user's password.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  # XDG Portal (for file picker, screen sharing in Hyprland)
  # xdg-desktop-portal-kde exposes color-scheme (dark mode) to Chrome/Gemini, etc.
  # via kdeglobals — no GNOME/GTK infrastructure required.
  # xdph alone doesn't implement the appearance protocol.
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.kdePackages.xdg-desktop-portal-kde
    ];
    config.common = {
      default = "hyprland;kde";
      "org.freedesktop.impl.portal.Settings" = "kde";
    };
  };

  # X11 (for XWayland) and Hyprland
  services.xserver.enable = true;

  # Écran de login graphique : greetd + regreet (voir modules/greetd.nix).
  # lightdm reste explicitement désactivé pour éviter tout conflit avec greetd
  # sur la VT si `services.xserver.enable = true` le proposait par défaut.
  services.xserver.displayManager.lightdm.enable = false;

  programs.hyprland.enable = true;

  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # Printing
  services.printing.enable = true;

  # Fonts — JetBrains Mono for text/UI, Noto Color Emoji for emoji glyphs
  fonts = {
    enableDefaultPackages = false;
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "JetBrains Mono" ];
        sansSerif = [ "JetBrains Mono" ];
        monospace = [ "JetBrains Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
    packages = with pkgs; [
      jetbrains-mono
      monocraft
      noto-fonts-color-emoji
    ];
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    grimblast
    libnotify
  ];
}
