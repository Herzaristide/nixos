{
  config,
  pkgs,
  lib,
  ...
}:

{
  # NetworkManager (overridden to false on exupery/WSL)
  networking.networkmanager.enable = lib.mkDefault true;

  # SSH — password auth enabled for local development hosts
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
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
