{
  pkgs,
  inputs,
  config,
  ...
}:

{
  # MCP (Model Context Protocol) servers — writes ~/.config/mcp/mcp.json
  # Consumed by Claude Code (via enableMcpIntegration).
  programs.mcp = {
    enable = true;
    servers = {
      # Remote hébergé : un seul serveur distant, partagé par toutes les sessions
      # (fini le process local multiplié). Fonctionne en anonyme ; pour des limites
      # plus hautes, ajouter une clé via header, ex :
      #   headers.CONTEXT7_API_KEY = "{env:CONTEXT7_API_KEY}";
      # ({env:…} est résolu au runtime par le client → clé jamais dans le store).
      context7 = {
        url = "https://mcp.context7.com/mcp";
        type = "http";
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
      sequential-thinking = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-sequential-thinking"
        ];
        type = "stdio";
      };
      # Remote hébergé Tavily : clé passée en header Authorization, résolue au
      # runtime depuis l'env TAVILY_API_KEY (jamais écrite dans le store Nix).
      tavily = {
        url = "https://mcp.tavily.com/mcp/";
        type = "http";
        headers.Authorization = "Bearer {env:TAVILY_API_KEY}";
      };
      penpot = {
        url = "http://localhost:4401/mcp";
        type = "http";
      };
      # SonarQube Cloud (lecture des analyses : issues, quality gate, hotspots).
      # Serveur MCP officiel SonarSource, en conteneur Docker (virtualisation.docker
      # activé dans common.nix). Le jeton n'est jamais dans le store : {env:SONAR_TOKEN}
      # est résolu au runtime par le client puis transmis au conteneur via -e.
      # → exporter SONAR_TOKEN dans l'environnement de la session avant de lancer
      #   le client (même token que celui utilisé par la CI SonarCloud).
      sonarqube = {
        command = "docker";
        args = [
          "run"
          "--init"
          "--pull=always"
          "-i"
          "--rm"
          "-e"
          "SONARQUBE_TOKEN"
          "-e"
          "SONARQUBE_ORG"
          "sonarsource/sonarqube-mcp"
        ];
        type = "stdio";
        env = {
          SONARQUBE_TOKEN = "{env:SONAR_TOKEN}";
          SONARQUBE_ORG = "herzaristide";
        };
      };
    };
  };
}
