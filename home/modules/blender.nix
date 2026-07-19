{
  pkgs,
  lib,
  dgpu ? {
    vendor = null;
    driPrime = null;
  },
  ...
}:

let
  # Variables d'environnement forçant le rendu sur le GPU discret.
  #  - nvidia : PRIME offload (zola). Sans ces trois variables le driver Intel
  #    reste sélectionné, exactement comme avec le wrapper `nvidia-offload`.
  #  - amd    : DRI_PRIME pointe le GPU par son adresse PCI plutôt que par un
  #    index (`DRI_PRIME=1`), qui dépend de l'ordre d'énumération des cartes.
  gpuEnv =
    if dgpu.vendor == "nvidia" then
      {
        __NV_PRIME_RENDER_OFFLOAD = "1";
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        __VK_LAYER_NV_optimus = "NVIDIA_only";
      }
    else if dgpu.vendor == "amd" && dgpu.driPrime != null then
      { DRI_PRIME = dgpu.driPrime; }
    else
      { };

  # --set-default et non --set : le GPU reste surchargeable au lancement
  # (ex. `DRI_PRIME=0 blender` pour retomber sur l'iGPU).
  wrapFlags = lib.concatStringsSep " " (
    lib.mapAttrsToList (name: value: "--set-default ${name} ${lib.escapeShellArg value}") gpuEnv
  );

  # symlinkJoin + wrapProgram : le .desktop du paquet lance `blender` via le
  # PATH, il hérite donc du wrapper (pas besoin de dupliquer l'entrée desktop).
  blender =
    if gpuEnv == { } then
      pkgs.blender
    else
      pkgs.symlinkJoin {
        name = "blender-dgpu-${pkgs.blender.version}";
        paths = [ pkgs.blender ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/blender ${wrapFlags}
        '';
      };

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
  home.packages = [ blender ];

  home.file.".config/blender/${blenderVersion}/scripts/addons/blender_mcp_addon.py".source =
    "${blenderMcpAddon}/addon.py";
}
