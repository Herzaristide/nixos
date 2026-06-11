{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  jsonFormat = pkgs.formats.json { };

  # Translate programs.mcp.servers entries into the schema Claude Desktop
  # expects: { command, args, env } for stdio servers. Skip HTTP/SSE servers —
  # add those from inside Claude Desktop (OAuth flow stores tokens elsewhere).
  toClaudeDesktopServer =
    server:
    if (server.type or "stdio") != "stdio" then
      null
    else
      {
        command = server.command;
      }
      // lib.optionalAttrs (server ? args) { inherit (server) args; }
      // lib.optionalAttrs (server ? environment) { env = server.environment; }
      // lib.optionalAttrs (server ? env) { inherit (server) env; };

  claudeDesktopServers = lib.filterAttrs (_: v: v != null) (
    lib.mapAttrs (_: toClaudeDesktopServer) config.programs.mcp.servers
  );
in
{
  home.packages = [
    inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.claude-desktop-fhs
  ];

  xdg.configFile."Claude/claude_desktop_config.json" = {
    force = true;
    source = jsonFormat.generate "claude_desktop_config.json" {
      mcpServers = claudeDesktopServers;
    };
  };
}
