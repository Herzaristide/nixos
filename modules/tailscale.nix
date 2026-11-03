# VPN mesh WireGuard entre les machines.
{ config, lib, ... }:
{
  services.tailscale = {
    enable = true;
    openFirewall = true; # port UDP de WireGuard (41641), pas les services
    useRoutingFeatures = "client";
    # Par défaut (`on`), tailscaled branche sa chaîne ts-input en tête de
    # INPUT, et elle finit par `-i tailscale0 -j ACCEPT` : tout port de l'hôte
    # est ouvert au tailnet, quel que soit le pare-feu NixOS. `nodivert` crée
    # toujours ses chaînes mais ne les branche pas : c'est alors le pare-feu
    # NixOS (ci-dessous) qui décide de ce qui entre par tailscale0.
    extraSetFlags = [ "--netfilter-mode=nodivert" ];
  };

  # Plus de `trustedInterfaces = [ "tailscale0" ]` : seuls les ports déclarés
  # entrent par le tailnet. Chaque service l'ouvre lui-même là où il est défini
  # (hunyuan3d : 8081 sur gary ; agents : 8000-8099 sur kafka). Les postes
  # (bernanos, exupery), sans sshd, n'exposent rien au tailnet.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts =
    lib.optional config.services.openssh.enable 22;

  # Phase 2, après appairage : sshd via tailscale0 seul.
  # services.openssh.openFirewall = lib.mkForce false;
}
