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

  # No display manager / greeter: getty auto-logs in `aristide` on tty1,
  # and the fish login shell exec's Hyprland directly (see loginShellInit below).
  # `services.xserver.enable = true` otherwise pulls in lightdm by default, which
  # would grab the VT and show a graphical login — disable it explicitly.
  services.displayManager.enable = false;
  services.xserver.displayManager.lightdm.enable = false;
  services.getty.autologinUser = "aristide";

  # Launch Hyprland automatically on the first VT right after autologin.
  # Guarded so it only runs on tty1 and not inside an existing session.
  programs.fish.loginShellInit = ''
    if test -z "$WAYLAND_DISPLAY" -a (tty) = /dev/tty1
        ${lib.optionalString (config.renderDevice != null) ''
          # Pin the compositor's render GPU (see modules/common.nix renderDevice).
          # aquamarine crashes on the by-path symlink, so resolve it to the real
          # cardN node first. Guard on existence so a missing/renamed device
          # can't wedge the whole login (Hyprland would just autopick instead).
          if test -e ${config.renderDevice}
              set -x AQ_DRM_DEVICES (readlink -f ${config.renderDevice})
          end
        ''}
        exec ${config.programs.hyprland.package}/bin/start-hyprland
    end
  '';

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
