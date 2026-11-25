# Kubernetes (k3s), un seul nœud : plan de contrôle et pods sur la même
# machine. API joignable par le tailnet seulement. État dans /var/lib/rancher
# (sous /, hors impermanence).
{ config, ... }:
{
  services.k3s = {
    enable = true;
    role = "server"; # plan de contrôle + kubelet : les pods tournent aussi ici
    # Traefik et servicelb publieraient 80/443 sur le LAN : leurs ports sont
    # redirigés (DNAT) avant INPUT, donc hors de portée du pare-feu NixOS. Un pod
    # en `hostPort` ou un Service `externalIPs` le contournerait aussi.
    disable = [
      "traefik"
      "servicelb"
    ];
    extraFlags = [
      "--tls-san=${config.networking.hostName}" # certificat valide pour kubectl à distance
      "--secrets-encryption"
      "--write-kubeconfig-mode=0600"
      # NodePorts sur l'adresse Tailscale seulement (même raison : DNAT).
      "--kube-proxy-arg=nodeport-addresses=100.64.0.0/10"
    ];
    gracefulNodeShutdown.enable = true;
  };

  networking.firewall.interfaces = {
    tailscale0.allowedTCPPorts = [ 6443 ];
    # Pods → API et kubelet (metrics-server).
    cni0.allowedTCPPorts = [
      6443
      10250
    ];
  };
}
