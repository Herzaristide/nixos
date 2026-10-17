{
  pkgs,
  lib,
  ...
}:

{
  # Serveurs MCP sans compte ni accès personnel : partagés par les postes et les
  # VMs de dev (modules/devbox.nix). Les serveurs liés à un compte ou à zola
  # (linear, figma, tavily, filesystem, blender, penpot) sont dans ./mcp.nix.
  #
  # Les serveurs stdio packagés dans nixpkgs sont lancés depuis le store, pas
  # via `npx`/`uvx` : ces derniers résolvent et téléchargent le paquet à chaque
  # démarrage du serveur, donc du code non épinglé, hors flake.lock, exécuté
  # avec tous les droits de l'utilisateur. Le passage au store fige la version
  # dans le lock et supprime tout accès réseau à l'exécution.
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
      # Dans une VM, sert à Claude à tester lui-même l'app qu'il expose.
      playwright = {
        command = lib.getExe pkgs.playwright-mcp;
        type = "stdio";
      };
      sequential-thinking = {
        command = lib.getExe pkgs.mcp-server-sequential-thinking;
        type = "stdio";
      };
      # CodeGraph (colbymchenry/codegraph, nixpkgs) : graphe de symboles/appels
      # du projet, l'agent l'interroge au lieu de parcourir les fichiers (moins
      # d'appels d'outils et de tokens). Chaque projet doit être indexé une fois
      # avec `codegraph init` (crée `.codegraph/` dans le repo), ensuite le
      # serveur resynchronise l'index à chaque modification de fichier.
      # `alwaysLoad` évite que Claude Code cache l'outil derrière son tool-search.
      codegraph = {
        command = lib.getExe pkgs.codegraph;
        args = [
          "serve"
          "--mcp"
        ];
        type = "stdio";
        alwaysLoad = true;
        # Télémétrie d'usage active par défaut (opt-out, avec machine_id).
        env.CODEGRAPH_TELEMETRY = "0";
      };
    };
  };

  # CLI pour `codegraph init` / `status` / `sync`.
  home.packages = [ pkgs.codegraph ];
  home.sessionVariables.CODEGRAPH_TELEMETRY = "0";
}
