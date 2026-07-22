# VPN mesh WireGuard entre les machines.
{ ... }:
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # Phase 2, après appairage (ajouter `lib` aux args) : sshd via tailscale0 seul.
  # services.openssh.openFirewall = lib.mkForce false;
}
