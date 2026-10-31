{
  pkgs,
  lib,
  ...
}:

let
  # Le tarball upstream embarque son propre `node` (24.16, prébuild), qui
  # segfaulte dès `--version` sur wsl. On le remplace par celui de nixpkgs :
  # le seul module natif (codegraph-kernel.node) est N-API, donc indépendant
  # de la version exacte de node.
  codegraph = pkgs.codegraph.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      ln -sf ${lib.getExe pkgs.nodejs_24} $out/lib/codegraph/node
    '';
  });
in
{
  # MCP (Model Context Protocol) servers — writes ~/.config/mcp/mcp.json
  # Consumed by Claude Code (via enableMcpIntegration).
  #
  # Tous les serveurs partout : sur les postes comme pour l'utilisateur `claude`
  # des agents (modules/agents.nix). Ceux liés à un compte s'authentifient par
  # utilisateur ; ceux qui visent des services de bernanos (blender, penpot) ou des
  # dossiers d'aristide (filesystem) restent simplement inopérants ailleurs.
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
      #   headers.CONTEXT7_API_KEY = "\${CONTEXT7_API_KEY}";
      # (`${VAR}` est résolu au runtime par Claude Code → clé jamais dans le
      # store ; le module ne traduit pas les headers, et la syntaxe opencode
      # `{env:…}` y serait transmise telle quelle).
      context7 = {
        url = "https://mcp.context7.com/mcp";
        type = "http";
      };
      # Sert notamment à Claude à tester lui-même l'app qu'il expose.
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
        command = lib.getExe codegraph;
        args = [
          "serve"
          "--mcp"
        ];
        type = "stdio";
        alwaysLoad = true;
        # Télémétrie d'usage active par défaut (opt-out, avec machine_id).
        env.CODEGRAPH_TELEMETRY = "0";
      };
      linear = {
        url = "https://mcp.linear.app/mcp";
        type = "http";
      };
      # Périmètre limité aux dossiers de travail, et surtout PAS à /home/aristide
      # entier : la racine du home donne accès à ~/.ssh et ~/.aws, tous deux
      # persistés par impermanence. Leur mode 0700 ne protège de rien face à un
      # process tournant sous le même uid.
      # Ajouter un dossier ici est une décision explicite.
      filesystem = {
        command = lib.getExe pkgs.mcp-server-filesystem;
        args = [
          "/home/aristide/code"
          "/home/aristide/docs"
          "/home/aristide/drop"
          # La config NixOS a quitté ~/ghub pour /etc/nixos.
          "/etc/nixos"
        ];
        type = "stdio";
      };
      # Pilotage de Blender : le serveur parle à l'add-on BlenderMCP (socket
      # 9876, déposé par home/modules/blender.nix) — Blender doit tourner et
      # l'add-on être connecté pour que les outils répondent.
      # Seul serveur stdio encore lancé par un résolveur externe :
      # mcp-for-blender (ex-blender-mcp, renommé en 2.x) n'est pas packagé
      # dans nixpkgs. `uvx` le résout, mais épinglé sur la release de
      # home/modules/blender-mcp-release.nix — la même que l'add-on.
      blender = {
        command = "${pkgs.uv}/bin/uvx";
        args = [ "mcp-for-blender==${(import ../../blender-mcp-release.nix).version}" ];
        type = "stdio";
      };
      penpot = {
        url = "http://localhost:4401/mcp";
        type = "http";
      };
    };
  };

  # CLI pour `codegraph init` / `status` / `sync`.
  home.packages = [ codegraph ];
  home.sessionVariables.CODEGRAPH_TELEMETRY = "0";
}
