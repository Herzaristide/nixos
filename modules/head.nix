{
  pkgs,
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

  # PAM service for the Quickshell lockscreen (karenine's lock.qml, via
  # PamContext { config: "quickshell" }). Without this file the lock has no way
  # to validate the password and every attempt fails with a PAM start error.
  # The stock NixOS stack (unix auth) is what we want here — same as a console
  # login. `enableGnomeKeyring` mirrors the login service so unlocking the
  # session also unlocks the keyring git-credential-manager stores into.
  security.pam.services.quickshell.enableGnomeKeyring = true;

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

  programs.hyprland.enable = true;

  # `start-hyprland` (le lanceur utilisé par la session utilisateur comme par
  # celle du greeter, cf. modules/greetd.nix) délègue à uwsm. Sans ce module ses
  # unités systemd user (wayland-session-bindpid@, wayland-wm@) n'existent pas :
  # uwsm échoue avec « returned non-zero exit status 5 » et la session meurt
  # aussitôt, renvoyant sur l'écran de login.
  # `enable` seul n'installe que le paquet et ses unités ; on ne veut PAS
  # `programs.hyprland.withUWSM`, qui ajouterait une entrée hyprland-uwsm.desktop
  # concurrente de la nôtre (celle-ci porte le pinning GPU AQ_DRM_DEVICES).
  programs.uwsm.enable = true;

  services.xserver.xkb = {
    layout = "fr";
    variant = "";
  };

  # Printing
  services.printing.enable = true;

  # OpenRGB — contrôle RGB. Le `motherboard` (chemin SMBus à charger) et les
  # règles d'application de l'accent restent par hôte : les périphériques
  # diffèrent (cf. hosts/gary pour RAM + ventilateurs).
  #
  # Désactivé ici le temps des tests sur le clavier de zola : sur ce laptop
  # OpenRGB ne détecte aucun contrôleur (`--list-devices` → 0, aucune chaîne
  # SteelSeries dans le binaire : le KLC 1038:113a n'a pas de driver amont) et
  # ne sert donc à rien tant qu'on n'en aura pas écrit un. Activé chez gary,
  # seul hôte qui a des périphériques reconnus.
  # services.hardware.openrgb.enable = true;

  # Fonts — JetBrains Mono for text/UI, Noto Color Emoji for emoji glyphs.
  # terminus_font_ttf est la variante TrueType de la police du TTY
  # (console.font = "ter-v32n", cf. modules/common.nix) : le paquet
  # terminus_font n'expose que des bitmaps PSF, que fontconfig ignore.
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
      terminus_font_ttf
    ];
  };

  environment.systemPackages = with pkgs; [
    brightnessctl
    grimblast
    libnotify
  ];
}
