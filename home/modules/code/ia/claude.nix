{ pkgs, ... }:

{
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;

    # Consume programs.mcp.servers (defined in ./mcp.nix) — Claude Code merges them
    # into its own MCP config so the same servers are available across tools.
    enableMcpIntegration = true;
  };
}
