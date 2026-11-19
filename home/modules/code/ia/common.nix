{ ... }:

{
  # Partie de la config Claude Code sans accès au coffre (réglages, LSP, rtk, MCP),
  # importée par ./default.nix.
  imports = [
    ./claude.nix
    ./mcp.nix
    ./rtk.nix
  ];
}
