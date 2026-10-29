{
  pkgs,
  lib,
  ...
}:

let
  # Add-on socket (port 9876) auquel le serveur MCP `blender` se connecte.
  # Extrait du wheel `mcp-for-blender` épinglé dans blender-mcp-release.nix,
  # le même que lance le serveur : add-on et serveur sont toujours de la même
  # release. Côté Nix on ne fait que déposer le fichier : il reste à cocher
  # « MCP for Blender » dans Preferences → Add-ons (une fois, l'état est dans
  # userpref.blend). Le serveur socket démarre ensuite à l'ouverture de
  # Blender (panneau latéral N → MCP for Blender pour vérifier).
  release = import ./blender-mcp-release.nix;

  blenderMcpAddon =
    pkgs.runCommand "mcp-for-blender-addon-${release.version}"
      {
        src = pkgs.fetchurl {
          url = release.wheelUrl;
          hash = release.wheelHash;
        };
        nativeBuildInputs = [ pkgs.unzip ];
      }
      ''
        unzip -p "$src" blender_mcp/bundled/addon.py > $out
      '';

  blenderVersion = lib.versions.majorMinor pkgs.blender.version;
in
{
  # Module headful seulement (bernanos, exupery). Backend Cycles compilé dans
  # le paquet : CUDA/OptiX sur bernanos (overlay blender dans son
  # configuration.nix), CPU/iGPU Intel sur exupery.
  home.packages = [ pkgs.blender ];

  # Nom de fichier = nom de module de l'add-on ; `blender_mcp.py` est celui
  # qu'utilise `mcp-for-blender install-addon`.
  home.file.".config/blender/${blenderVersion}/scripts/addons/blender_mcp.py".source =
    blenderMcpAddon;
}
