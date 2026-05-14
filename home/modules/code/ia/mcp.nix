{ pkgs, ... }:

{
  # MCP (Model Context Protocol) servers — writes ~/.config/mcp/mcp.json
  # Consumed by Claude Code (via enableMcpIntegration) and VSCode (via userMcp).
  programs.mcp = {
    enable = true;
    servers = {
      context7 = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "@upstash/context7-mcp@latest"
        ];
        type = "stdio";
      };
      docker = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "@docker/mcp-server"
        ];
        type = "stdio";
      };
      playwright = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [ "@playwright/mcp@latest" ];
        type = "stdio";
      };
      # Linear: remote MCP server, OAuth on first connection (browser flow).
      linear = {
        url = "https://mcp.linear.app/sse";
        type = "sse";
      };
      # Figma: stdio via figma-developer-mcp (Linux has no Figma Desktop, so no
      # official Dev Mode local server). Requires FIGMA_API_KEY in the env of
      # whichever client spawns this command.
      figma = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "figma-developer-mcp"
          "--stdio"
        ];
        type = "stdio";
      };
      # Filesystem: read/write under the listed root. Extend args with more
      # directories to widen access.
      filesystem = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/home/aristide"
        ];
        type = "stdio";
      };
      # Postgres: read-only DB introspection. Replace the connection string with
      # a real one (e.g. postgresql://user:pass@host:5432/db).
      postgres = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-postgres"
          "postgresql://localhost/postgres"
        ];
        type = "stdio";
      };
      # Sequential Thinking: reasoning tool, no config needed.
      sequential-thinking = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
        type = "stdio";
      };
      # Tavily: web search. Requires TAVILY_API_KEY in the client's env.
      tavily = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "tavily-mcp"
        ];
        type = "stdio";
      };
    };
  };
}
