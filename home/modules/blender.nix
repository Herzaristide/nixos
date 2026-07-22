{
  pkgs,
  lib,
  ...
}:

let
  # Add-on socket (port 9876) auquel le serveur MCP `blender` se connecte.
  # Côté Nix on ne fait que déposer le fichier : il reste à cocher l'add-on
  # dans Preferences → Add-ons, puis « Connect to MCP server » dans le panneau
  # latéral (N) → BlenderMCP.
  blenderMcpAddon = pkgs.fetchFromGitHub {
    owner = "ahujasid";
    repo = "blender-mcp";
    rev = "6641189231caf3752302ae20591bc87fda85fc4e";
    hash = "sha256-4I5pLS4bf0PrPUolbrsGrZmnEhMFLlL0ELYIBBeHUns=";
  };

  blenderVersion = lib.versions.majorMinor pkgs.blender.version;
in
{
  # Cycles choisit sa carte lui-même dans Preferences → System → Cycles Render
  # Devices, via le backend de calcul compilé dans le paquet. Sur gary, HIP est
  # activé par le `rocmSupport` de l'hôte (binaires ROCm dans le cache Hydra,
  # aucun coût). Sur zola en revanche, le `cudaSupport` global a été retiré (il
  # recompilait ~29 paquets absents du cache CUDA) : `pkgs.blender` y arrive
  # donc pré-buildé mais SANS backend CUDA/OptiX, Cycles y rend en CPU. Le
  # rétablir imposerait de recompiler blender localement (rebrancher
  # `cudaSupport` ou un override `pkgs.blender.override { cudaSupport = true; }`).
  home.packages = [ pkgs.blender ];

  home.file.".config/blender/${blenderVersion}/scripts/addons/blender_mcp_addon.py".source =
    "${blenderMcpAddon}/addon.py";
}
