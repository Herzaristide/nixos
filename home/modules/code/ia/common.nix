{ ... }:

{
  # Partie de la config Claude Code sans accès au coffre (réglages, LSP, rtk, MCP) :
  # importée par ./default.nix sur les postes et, seule, pour l'utilisateur
  # `claude` des agents (modules/agents.nix).
  imports = [
    ./claude.nix
    ./mcp.nix
    ./rtk.nix
  ];
}
