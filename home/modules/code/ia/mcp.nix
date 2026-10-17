{
  pkgs,
  lib,
  ...
}:

{
  # MCP (Model Context Protocol) servers — writes ~/.config/mcp/mcp.json
  # Consumed by Claude Code (via enableMcpIntegration).
  #
  # Serveurs liés à un compte, une clé ou à des services de zola : postes
  # seulement. Ceux sans accès personnel, aussi présents dans les VMs de dev,
  # sont dans ./mcp-common.nix (même règle store plutôt que npx/uvx).
  programs.mcp = {
    enable = true;
    servers = {
      linear = {
        url = "https://mcp.linear.app/mcp";
        type = "http";
      };
      figma = {
        url = "https://mcp.figma.com/mcp";
        type = "http";
      };
      # Périmètre limité aux dossiers de travail, et surtout PAS à /home/aristide
      # entier : la racine du home donne accès à ~/.ssh et ~/.aws, tous deux
      # persistés par impermanence. Leur mode 0700 ne protège de rien face à un
      # process tournant sous le même uid.
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
      penpot = {
        url = "http://localhost:4401/mcp";
        type = "http";
      };
    };
  };

}
