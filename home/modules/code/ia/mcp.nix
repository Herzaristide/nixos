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
      # Linear: remote MCP server, OAuth on first connection (browser flow).
      # Migrated to Streamable HTTP transport (/mcp) — SSE endpoint deprecated.
      linear = {
        url = "https://mcp.linear.app/mcp";
        type = "http";
      };
      # Figma: remote MCP, authenticate once via OAuth in Claude Code.
      # Uses Streamable HTTP transport (not SSE — SSE endpoint /sse is gone).
      figma = {
        url = "https://mcp.figma.com/mcp";
        type = "http";
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
      # Oracle Cloud (OCI): Oracle Database access via mcp-server-oracle.
      # Requires ORACLE_DSN, ORACLE_USER, ORACLE_PASSWORD in the client's env.
      oracle = {
        command = "${pkgs.uv}/bin/uvx";
        args = [ "mcp-server-oracle" ];
        type = "stdio";
      };
      # AWS: general-purpose AWS API access via the AWS CLI (awslabs official).
      # Uses standard AWS credentials (~/.aws/credentials or env vars).
      # NOTE: awslabs.core-mcp-server was yanked from PyPI ("load individual
      # MCPs"); aws-api-mcp-server is the closest general-purpose replacement.
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
