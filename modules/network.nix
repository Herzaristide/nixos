{
  config,
  pkgs,
  lib,
  ...
}:

{
  # NetworkManager (overridden to false on exupery/WSL)
  networking.networkmanager.enable = lib.mkDefault true;

  # SSH
  # PasswordAuthentication is still on, awaiting `users.users.aristide.openssh.authorizedKeys.keys`
  # to be populated; once keys are deployed, flip this to false.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false; # 2FA not configured; this is just another password path
      PermitRootLogin = "no";
      # Reasonable defaults; explicit for audit clarity
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
