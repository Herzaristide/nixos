{
  pkgs,
  lib,
  ...
}:

{
  # MCP (Model Context Protocol) servers — writes ~/.config/mcp/mcp.json
  # Consumed by Claude Code (via enableMcpIntegration).
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
      playwright = {
        command = lib.getExe pkgs.playwright-mcp;
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
      # Périmètre limité aux dossiers de travail, et surtout PAS à /home/aristide
      # entier : la racine du home donne accès à ~/.ssh, ~/.aws et
      # ~/.config/rclone, tous persistés par impermanence. Leur mode 0700 ne
      # protège de rien face à un process tournant sous le même uid.
      # Ajouter un dossier ici est une décision explicite : ~/d3pot, l'archive,
      # en est volontairement absent.
      filesystem = {
        command = lib.getExe pkgs.mcp-server-filesystem;
        args = [
          "/home/aristide/ciph3r"
          "/home/aristide/sc0re"
          "/home/aristide/f3tch"
          # La config NixOS a quitté ~/ghub pour /etc/nixos.
          "/etc/nixos"
        ];
        type = "stdio";
      };
      sequential-thinking = {
        command = lib.getExe pkgs.mcp-server-sequential-thinking;
        type = "stdio";
      };
      # Remote hébergé Tavily : clé passée en header Authorization, résolue au
      # runtime depuis l'env TAVILY_API_KEY (jamais écrite dans le store Nix).
      tavily = {
        url = "https://mcp.tavily.com/mcp/";
        type = "http";
        headers.Authorization = "Bearer {env:TAVILY_API_KEY}";
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
      # Surface MCPHttp intégrée à Ardour 9 (home/modules/music/ardour.nix) :
      # répond seulement quand Ardour tourne avec la surface activée dans
      # Preferences → Control Surfaces. Port par défaut 4820, fermé par le
      # pare-feu (seul le 22 est ouvert) donc injoignable hors de la machine.
      ardour = {
        url = "http://127.0.0.1:4820/mcp";
        type = "http";
      };
      penpot = {
        url = "http://localhost:4401/mcp";
        type = "http";
      };
    };
  };
}
