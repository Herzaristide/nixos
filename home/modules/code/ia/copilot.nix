{ pkgs, ... }:

{
  programs.github-copilot-cli = {
    enable = true;
    package = pkgs.github-copilot-cli;

    # Consume programs.mcp.servers (defined in ./mcp.nix) — Copilot CLI writes
    # them into ~/.copilot/mcp-config.json with the right shape.
    enableMcpIntegration = true;
  };
}
