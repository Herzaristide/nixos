# Clients Kubernetes : le cluster k3s tourne sur gary (modules/k3s.nix).
# Le kubeconfig (~/.kube/config, accès admin) est persisté par impermanence.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    kubectl
    kubernetes-helm
    k9s
  ];
}
