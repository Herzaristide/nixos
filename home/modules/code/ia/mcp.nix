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
          "mcp-server-docker"
        ];
        type = "stdio";
      };
      playwright = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [ "@playwright/mcp@latest" ];
        type = "stdio";
      };
      linear = {
        url = "https://mcp.linear.app/mcp";
        type = "http";
      };
      figma = {
        url = "https://mcp.figma.com/mcp";
        type = "http";
      };
      filesystem = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/home/aristide"
        ];
        type = "stdio";
      };
      postgres = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-postgres"
          "postgresql://localhost/postgres"
        ];
        type = "stdio";
      };
      sequential-thinking = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
        type = "stdio";
      };
      tavily = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "tavily-mcp"
        ];
        type = "stdio";
      };
      oracle = {
        command = "${pkgs.uv}/bin/uvx";
        args = [ "mcp-server-oracle" ];
        type = "stdio";
      };
      reaper = {
        command = "${pkgs.uv}/bin/uvx";
        args = [ "reaper-mcp-server" ];
        type = "stdio";
      };
      aws = {
        command = "${pkgs.uv}/bin/uvx";
        args = [ "awslabs.aws-api-mcp-server@latest" ];
        type = "stdio";
        environment = {
          FASTMCP_LOG_LEVEL = "ERROR";
        };
      };
    };
  };
}
