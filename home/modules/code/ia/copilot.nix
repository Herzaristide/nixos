{ pkgs, ... }:

{
  programs.github-copilot-cli = {
    enable = true;
    package = pkgs.github-copilot-cli;

    # Réutilise programs.mcp.servers (défini dans ./mcp.nix) — écrit dans
    # ~/.copilot/mcp-config.json au bon format.
    enableMcpIntegration = true;
  };
}
