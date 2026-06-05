{
  config,
  pkgs,
  lib,
  ...
}:

{
  # NetworkManager (overridden to false on exupery/WSL)
  networking.networkmanager.enable = lib.mkDefault true;
  networking.networkmanager.wifi.macAddress = "stable";
  networking.networkmanager.ethernet.macAddress = "stable";

  # SSH — key-only authentication.
  services.openssh = {
    enable = true;
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

  networking.hosts = {
    "0.0.0.0" = [
      "youtube.com"
      "www.youtube.com"
      "m.youtube.com"
      "studio.youtube.com"
      "tv.youtube.com"
      "kids.youtube.com"
      "gaming.youtube.com"
      "youtu.be"
      "youtubekids.com"
      "www.youtubekids.com"
      "twitch.tv"
      "www.twitch.tv"
      "m.twitch.tv"
      "clips.twitch.tv"
      "player.twitch.tv"
      "go.twitch.tv"
      "safety.twitch.tv"
    ];
  };

  # Wake-on-LAN : arme toutes les interfaces Ethernet filaires au boot.
  # Why: permet de réveiller kafka/gary/zola à distance via un magic packet
  # (la NIC reste alimentée et écoute même machine éteinte, si autorisé BIOS).
  # How to apply: oneshot systemd qui appelle `ethtool -s <iface> wol g` sur
  # chaque interface réelle. Skip auto les loopback/virtual/wireless et les
  # NIC qui ne supportent pas WoL (cas WSL) — donc safe à activer partout.
  systemd.services.wake-on-lan = {
    description = "Enable Wake-on-LAN on all wired interfaces";
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
          ethtool -s "$name" wol g || true
        fi
      done
    '';
  };

  # Firewall configuration
  networking.firewall = {
    enable = lib.mkDefault true;
    allowedTCPPorts = [
      22 # SSH
      80 # HTTP
    ];
    allowedUDPPorts = [
      51820 # WireGuard
      51821 # WireGuard IPv6
    ];
    trustedInterfaces = [ "lo" ];
  };
}
