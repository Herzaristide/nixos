{
  config,
  pkgs,
  lib,
  ...
}:

{
  # NetworkManager (overridden to false on exupery/WSL)
  networking.networkmanager.enable = lib.mkDefault true;

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
