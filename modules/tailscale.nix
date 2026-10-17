# VPN mesh WireGuard entre les machines.
{ lib, ... }:
let
  # VMs de dev de chaque hôte (modules/devbox.nix), joignables par la route que
  # leur hôte annonce sur le tailnet.
  devHosts = import ./devbox-vms.nix;
  vmHosts = lib.concatMapAttrs (
    _: h: lib.mapAttrs' (name: vm: lib.nameValuePair "${h.subnet}.${toString vm.ip}" [ name ]) h.vms
  ) devHosts;
in
{
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "client";
    # Accepte les sous-réseaux de VMs annoncés par les autres hôtes.
    extraSetFlags = [ "--accept-routes" ];
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # http://dev1:8000 depuis n'importe quelle machine du tailnet.
  networking.hosts = vmHosts;

  # Phase 2, après appairage : sshd via tailscale0 seul.
  # services.openssh.openFirewall = lib.mkForce false;
}
