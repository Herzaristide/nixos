{
  config,
  pkgs,
  ...
}:

# Couche graphique : tout ce qui sert à un hôte à écran, indépendamment du
# matériel (CPU, GPU, alimentation, caméra et écrans restent dans
# hosts/<hôte>/configuration.nix). L'importer suffit : il pose `head = true`.
{
  imports = [
    ./greetd.nix
    ./nautilus.nix
  ];

  head = true;

  # Démarrage silencieux : ni messages du noyau, ni statut des unités systemd,
  # ni sortie d'udev sur la console — seuls les messages d'erreur (niveau ≤ 3)
  # passent encore. Le journal garde tout (`journalctl -b`).
  boot.consoleLogLevel = 3;
  boot.kernelParams = [
    "quiet"
    "udev.log_level=3"
    "rd.udev.log_level=3"
    "systemd.show_status=auto"
    "rd.systemd.show_status=auto"
  ];

  # Animation de chargement à la place du texte (thème bgrt : logo du
  # constructeur et roue qui tourne), y compris la demande de phrase de passe
  # LUKS. Pas avec unl0kr (clavier virtuel de l'initrd sur exupery), que
  # l'amont ne prévoit pas de faire tourner avec Plymouth (avertissement du
  # module nixpkgs) : là, le démarrage reste juste silencieux.
  boot.plymouth.enable = !config.boot.initrd.unl0kr.enable;

  # Disable the experimental Fontations (Rust/Skrifa) font rendering backend.
  # NixOS 26.05 enables FC_FONTATIONS=1 by default, but this causes white/blank
  # glyph squares in GTK popup windows (file dialogs, git popups, etc.).
  # Force the stable FreeType backend instead.
  environment.variables.FC_FONTATIONS = "0";

  # Run Electron/Chromium apps in native Wayland mode. Required so Chromium uses
  # wl_data_device for drag-and-drop: without it Chromium runs under XWayland and
  # cross-protocol DnD from native Wayland apps (Nautilus) silently fails.
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

  # Reconnaissance faciale (howdy). Enregistrer son visage une fois par
  # machine avec `sudo howdy add` (état sous /etc et /var/lib, racine non
  # effacée par l'impermanence). La caméra (`settings.video.device_path`) est
  # du matériel : chaque hôte la fixe dans sa configuration.
  services.howdy = {
    enable = true;
    # « sufficient » : le visage suffit, le mot de passe reste possible en
    # repli. Le défaut « required » en ferait un second facteur obligatoire.
    control = "sufficient";
  };
  # howdy se trompe avec une bonne photo : il ne déverrouille que l'écran de
  # verrouillage (Quickshell) et les invites polkit. Ni greetd/login — le mot
  # de passe y déverrouille aussi GNOME Keyring (pam_gnome_keyring), qu'un
  # login par visage laisserait verrouillé —, ni sudo, qui reste au mot de passe.
  security.pam.howdy.enable = false;
  security.pam.services.quickshell.howdy.enable = true;
  security.pam.services.polkit-1.howdy.enable = true;

  # XDG Portal (for file picker, screen sharing in Hyprland)
  # xdg-desktop-portal-kde exposes color-scheme (dark mode) to Chrome/Gemini, etc.
  # via kdeglobals — no GNOME/GTK infrastructure required.
  # xdph alone doesn't implement the appearance protocol.
  # xdph itself comes from programs.hyprland (portalPackage, built against the
  # session's Hyprland): listing pkgs.xdg-desktop-portal-hyprland here too adds
  # a second store path and user-units fails on the duplicate .service.
  xdg.portal = {
    enable = true;
    extraPortals = [
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

  # OpenRGB — contrôle RGB. Le `motherboard` (chemin SMBus à charger) et les
  # règles d'application de l'accent restent par hôte : les périphériques
  # diffèrent (cf. hosts/gary pour RAM + ventilateurs).
  #
  # Désactivé ici le temps des tests sur le clavier de bernanos : sur ce laptop
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
      # Inter : la barre de conversation de karenine (texte façon macOS).
      inter
      monocraft
      noto-fonts-color-emoji
      terminus_font_ttf
    ];
  };

  # KDE Connect : le téléphone (notifications, presse-papier, fichiers, le
  # faire sonner). Ouvre 1714-1764 TCP/UDP au pare-feu, pour le trouver sur
  # le Wi-Fi. `kdeconnectd` est lancé avec la session Hyprland
  # (home/modules/hyprland/hyprland.nix) ; l'onglet « Téléphone » de karenine
  # le lit par D-Bus (anna/src/phone.rs). Les clés d'appairage vivent dans
  # ~/.config/kdeconnect, persisté (modules/impermanence.nix).
  programs.kdeconnect.enable = true;

  # Enregistrer l'écran (bouton de la barre du haut de karenine, Ctrl+Impr) :
  # anna lance gpu-screen-recorder, qui encode sur la carte graphique. Le
  # module pose le wrapper gsr-kms-server (cap_sys_admin) qui lit l'écran
  # sans passer par le portail, donc sans fenêtre de choix à chaque fois.
  programs.gpu-screen-recorder.enable = true;

  environment.systemPackages = with pkgs; [
    brightnessctl
    grimblast
    libnotify
    # « Fichiers » de KDE Connect monte le téléphone en sftp par sshfs.
    sshfs
    # L'écran du téléphone Android dans une fenêtre (bouton « Écran » de
    # l'onglet Téléphone). adb : anna y choisit l'appareil (USB, sinon
    # Tailscale). L'accès USB passe par les règles uaccess de systemd, sans
    # groupe ; la clé adbkey est dans ~/.android, persisté.
    scrcpy
    android-tools
  ];
}
