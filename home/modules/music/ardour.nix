{ pkgs, ... }:

{
  # Ardour 9 embarque sa propre surface de contrôle MCP (libardour_mcp_http),
  # branchée côté Claude dans home/modules/code/ia/mcp.nix. Rien à déposer
  # côté Nix : il reste à cocher « MCPHttp » une fois dans Preferences →
  # Control Surfaces (l'état vit dans ~/.config/ardour9, persisté par
  # modules/impermanence.nix). Laisser décochée l'option « toutes les
  # interfaces réseau » : le serveur n'a aucune authentification.
  home.packages = [ pkgs.ardour ];
}
