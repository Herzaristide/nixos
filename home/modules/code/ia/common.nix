{ ... }:

{
  # Partie de la config Claude Code sans compte, clé ni accès au coffre :
  # importée par ./default.nix sur les postes et, seule, dans les VMs de dev
  # (modules/devbox.nix).
  imports = [
    ./claude.nix
    ./mcp-common.nix
    ./rtk.nix
  ];
}
