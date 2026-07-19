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
  # Devices, via le backend de calcul compilé dans le paquet — HIP sur gary,
  # CUDA/OptiX sur zola, activés par les flags `rocmSupport`/`cudaSupport` des
  # hôtes. Rien à épingler ici : DRI_PRIME/__NV_* ne déplaceraient que le
  # viewport OpenGL, pas le rendu.
  home.packages = [ pkgs.blender ];

  home.file.".config/blender/${blenderVersion}/scripts/addons/blender_mcp_addon.py".source =
    "${blenderMcpAddon}/addon.py";
}
