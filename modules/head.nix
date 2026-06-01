{
  config,
  pkgs,
  inputs,
  ...
}:

{
  # Disable the experimental Fontations (Rust/Skrifa) font rendering backend.
  # NixOS 26.05 enables FC_FONTATIONS=1 by default, but this causes white/blank
  # glyph squares in GTK popup windows (file dialogs, git popups, etc.).
  # Force the stable FreeType backend instead.
  environment.variables.FC_FONTATIONS = "0";

  # dconf: required for GTK app settings and GNOME applications
  programs.dconf.enable = true;

  # GNOME Keyring (Secret Service daemon) for git-credential-manager `secretservice` store.
  # PAM hook unlocks the keyring at login with the user's password.
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;

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
      # xdph does not implement org.freedesktop.portal.Settings; route explicitly to kde
      # so Chromium and Qt apps read color-scheme from kdeglobals.
      "org.freedesktop.portal.Settings" = "kde";
    };
  };

  # X11 (for XWayland) and Hyprland
  services.xserver.enable = true;

  # Greetd with tuigreet (TUI login prompt) launching Hyprland.
  # Use start-hyprland, not Hyprland: the wrapper sets XDG vars, portals, screen sharing.
  # greetd is pinned to VT1 upstream, so isolation from boot logs relies on the quiet
  # kernelParams + consoleLogLevel below to keep tty1 clean while tuigreet draws.
  services.greetd = {
    enable = true;
    settings = {
      # Épingle greetd sur VT1 et force le switch au (re)démarrage.
      # Why: sans ça, `loginctl terminate-user` relance greetd sur le prochain VT
      # libre et laisse l'ancien VT (où était Hyprland) vide → curseur qui clignote
      # sans possibilité de retrouver l'écran de login.
      terminal = {
        vt = 1;
        switch = true;
      };
      default_session = {
        command = builtins.concatStringsSep " " [
          "${pkgs.tuigreet}/bin/tuigreet"
          "--time"
          "--time-format '%A %d %B — %H:%M'"
          "--remember"
          "--remember-user-session"
          "--asterisks"
          "--asterisks-char '*'"
          "--greeting 'Bienvenue, aristide.'"
          "--window-padding 4"
          "--container-padding 2"
          "--prompt-padding 1"
          "--theme 'border=magenta;text=white;prompt=magenta;time=cyan;action=blue;button=magenta;container=black;input=white;greet=cyan'"
          "--power-shutdown 'systemctl poweroff'"
          "--power-reboot 'systemctl reboot'"
          "--cmd '${config.programs.hyprland.package}/bin/start-hyprland'"
        ];
        user = "greeter";
      };
    };
  };

  # Silence kernel + initrd chatter so tuigreet isn't overwritten by late boot messages.
  # boot.kernelParams = [
  #   "quiet"
  #   "loglevel=3"
  #   "rd.udev.log_level=3"
  #   "udev.log_level=3"
  #   "vt.global_cursor_default=0"
  # ];
  # boot.consoleLogLevel = 0;
  # boot.initrd.verbose = false;

  programs.hyprland.enable = true;
  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # Printing
  services.printing.enable = true;

  # Fonts — single font family: JetBrains Mono
  fonts = {
    enableDefaultPackages = false;
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [ "JetBrains Mono" ];
        sansSerif = [ "JetBrains Mono" ];
        monospace = [ "JetBrains Mono" ];
        emoji = [ "JetBrains Mono" ];
      };
    };
    packages = with pkgs; [
      jetbrains-mono
      monocraft
    ];
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    grimblast
    libnotify
  ];
}
