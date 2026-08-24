{ pkgs, ... }:

{
  # Client Discord officiel (Electron), avec OpenASAR : désactive l'auto-update
  # (cassé/inutile sur NixOS, la version vient du store) et allège le client.
  home.packages = [
    (pkgs.discord.override { withOpenASAR = true; })
  ];

  # Empêche le client de tenter une mise à jour hors-Nix au démarrage.
  xdg.configFile."discord/settings.json".text = builtins.toJSON {
    SKIP_HOST_UPDATE = true;
  };

  # Entrée .desktop surchargée pour forcer Wayland natif (Ozone) + capture
  # PipeWire : c'est ce qui fait passer le partage d'écran par
  # xdg-desktop-portal-hyprland au lieu de XWayland (où la capture est cassée).
  xdg.desktopEntries.discord = {
    name = "Discord";
    genericName = "Messagerie vocale et texte";
    exec = "discord --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland %U";
    icon = "discord";
    categories = [
      "Network"
      "InstantMessaging"
    ];
    mimeType = [ "x-scheme-handler/discord" ];
    startupNotify = true;
  };
}
