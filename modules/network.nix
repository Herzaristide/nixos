{
  pkgs,
  lib,
  ...
}:

{
  # NetworkManager (overridden to false on wsl)
  networking.networkmanager.enable = lib.mkDefault true;
  networking.networkmanager.wifi.macAddress = "stable";
  networking.networkmanager.ethernet.macAddress = "stable";

  # SSH — key-only authentication. Désactivé par défaut : seuls gary et kafka
  # (serveurs) l'activent dans leur configuration.nix. Les réglages ci-dessous
  # ne s'appliquent que là où sshd tourne.
  services.openssh = {
    enable = lib.mkDefault false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
      AllowAgentForwarding = false;
      MaxAuthTries = 3;
      LoginGraceTime = 30;
    };
  };

  # Wake-on-LAN désactivé explicitement sur toutes les interfaces filaires.
  # Un magic packet n'est pas authentifié : n'importe qui sur le segment réseau
  # peut rallumer la machine. Ne pas se contenter de retirer l'activation —
  # le réglage `wol` vit dans le NIC et survit à un simple reboot une fois posé,
  # donc on force `wol d` au boot pour désarmer les cartes déjà configurées.
  # (Le firmware peut aussi l'activer de son côté : à couper dans le BIOS/UEFI
  # pour une désactivation complète.)
  systemd.services.disable-wake-on-lan = {
    description = "Disable Wake-on-LAN on all wired interfaces";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-pre.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = [ pkgs.ethtool ];
    script = ''
      for sys in /sys/class/net/*; do
        name=$(basename "$sys")
        [ "$name" = "lo" ] && continue
        [ -d "$sys/wireless" ] && continue
        [ ! -e "$sys/device" ] && continue
        if ethtool "$name" 2>/dev/null | grep -q 'Supports Wake-on:.*g'; then
          ethtool -s "$name" wol d || true
        fi
      done
    '';
  };

  networking.firewall = {
    enable = lib.mkDefault true;
    trustedInterfaces = [ "lo" ];
  };
}
