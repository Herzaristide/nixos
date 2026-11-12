# Serveur ComfyUI (génération d'images) sur le GPU ROCm de gary, pour
# l'extension Krita AI Diffusion de bernanos (modules/krita.nix, réglée sur
# « Custom server » : http://gary:8188) et pour Claude Code, qui pilote son API
# HTTP, via Tailscale.
#
# Même montage que modules/hunyuan3d.nix. Rien n'est ouvert sur le LAN : le
# service écoute sur 0.0.0.0 mais le port n'est ouvert que sur tailscale0.
#
# Tout est figé, sans venir de nixpkgs (torch ROCm n'y est pas en cache) :
#   - ComfyUI et ses nœuds personnalisés aux révisions qu'exige la release de
#     l'extension (pkgs/comfyui/krita-ai-diffusion.nix) ;
#   - les dépendances Python par pkgs/comfyui/uv.lock, synchronisées
#     (`uv sync --frozen`) à chaque démarrage ;
#   - les modèles par le script download_models.py de la même release.
# L'état (venv, cache uv, modèles, images produites, base sqlite) vit dans
# /var/lib/comfyui, que l'impermanence ne touche pas. Premier démarrage :
# ~6 Go de paquets Python puis ~20 Go de modèles, à suivre avec
# `journalctl -fu comfyui`.
#
# Modèles : tout ce qu'il faut pour SDXL (dont IP-Adapter, la référence de
# style), ses ControlNet (profondeur, contours… : la maquette grise guide la
# forme), et le checkpoint « ZavyChroma » (SDXL, illustration). Ajouter un
# jeu de modèles : changer `modelArgs` (voir `download_models.py --help`) ;
# le marqueur models/.downloaded-* change avec, et le script ne retélécharge
# que ce qui manque.
#
# Pas de démarrage au boot, et jamais en même temps que hunyuan3d (`conflicts`,
# réciproque) : à eux deux ils dépassent les 16 Gio de la RX 7600 XT. On le
# lance à la main : `sudo systemctl start comfyui`, puis `stop` après usage.
{ pkgs, lib, ... }:

let
  port = 8188;
  stateDir = "/var/lib/comfyui";

  release = import ../pkgs/comfyui/krita-ai-diffusion.nix;

  comfyui = pkgs.fetchFromGitHub {
    inherit (release.comfyui)
      owner
      repo
      rev
      hash
      ;
  };

  customNodes = map (
    n:
    n
    // {
      src = pkgs.fetchFromGitHub {
        inherit (n)
          owner
          repo
          rev
          hash
          ;
      };
    }
  ) release.customNodes;

  # Le zip de l'extension : seul download_models.py sert ici.
  plugin = pkgs.fetchzip {
    inherit (release) url hash;
    stripRoot = false;
  };

  modelArgs = "--sdxl --controlnet --checkpoint zavychroma --backend rocm";
  modelMarker = "models/.downloaded-${builtins.hashString "sha256" "${release.version} ${modelArgs}"}";

  project = builtins.path {
    name = "comfyui-project";
    path = ../pkgs/comfyui;
  };

  python = pkgs.python312;

  # Bibliothèques que les wheels manylinux (opencv, mediapipe, onnxruntime…)
  # s'attendent à trouver dans /usr/lib. torch ROCm embarque son propre ROCm.
  runtimeLibs = with pkgs; [
    stdenv.cc.cc.lib
    zlib
    libGL
    libglvnd
    glib
    numactl
    libx11
    libxext
    libxcb
    libsm
    libice
    # torch / triton
    zstd
    xz
    bzip2
    fontconfig
    freetype
  ];

  start = pkgs.writeShellScript "comfyui-start" ''
    set -euo pipefail
    cd ${stateDir}

    ${lib.getExe pkgs.uv} sync --frozen --project ${project} --python ${python}/bin/python3

    # Les nœuds personnalisés : liens vers le store, refaits à chaque démarrage
    # (un nœud retiré de la release disparaît). En lecture seule : leurs
    # téléchargements vont ailleurs (AUX_ANNOTATOR_CKPTS_PATH, HOME).
    mkdir -p custom_nodes
    find custom_nodes -maxdepth 1 -type l -delete
    ${lib.concatMapStringsSep "\n" (n: "ln -s ${n.src} custom_nodes/${n.folder}") customNodes}

    if [ ! -e ${modelMarker} ]; then
      echo "comfyui: téléchargement des modèles (${modelArgs})"
      venv/bin/python ${plugin}/ai_diffusion/download_models.py ${stateDir} ${modelArgs}
      rm -f models/.downloaded-*
      touch ${modelMarker}
    fi

    mkdir -p user
    exec venv/bin/python ${comfyui}/main.py \
      --listen 0.0.0.0 --port ${toString port} \
      --base-directory ${stateDir} \
      --database-url sqlite:///${stateDir}/user/comfyui.db \
      --disable-auto-launch
  '';
in
{
  systemd.services.comfyui = {
    description = "ComfyUI server (ROCm)";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    conflicts = [ "hunyuan3d.service" ];

    environment = {
      HOME = stateDir;
      HF_HOME = "${stateDir}/huggingface";
      # Poids des préprocesseurs (profondeur, contours) : par défaut dans le
      # dossier du nœud, ici en lecture seule.
      AUX_ANNOTATOR_CKPTS_PATH = "${stateDir}/aux-ckpts";
      UV_CACHE_DIR = "${stateDir}/uv-cache";
      UV_PROJECT_ENVIRONMENT = "${stateDir}/venv";
      UV_PYTHON_DOWNLOADS = "never";
      # Les wheels torch ROCm font plusieurs Go : le délai par défaut (30 s) casse.
      UV_HTTP_TIMEOUT = "300";
      LD_LIBRARY_PATH = lib.makeLibraryPath runtimeLibs;
      # Mêmes réglages ROCm que modules/hunyuan3d.nix (voir ses commentaires) :
      # la RX 7600 XT (gfx1102) vue comme gfx1100, l'iGPU écarté, l'attention
      # efficace activée sur RDNA3, les solveurs MIOpen « Winograd Fury »
      # coupés (ils plantent les convolutions fp16 des VAE sur la gfx1102).
      HSA_OVERRIDE_GFX_VERSION = "11.0.0";
      HIP_VISIBLE_DEVICES = "0";
      TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL = "1";
      MIOPEN_DEBUG_AMD_WINOGRAD_FURY_RXS_F2X3 = "0";
      MIOPEN_DEBUG_AMD_WINOGRAD_FURY_RXS_F3X2 = "0";
    };

    serviceConfig = {
      ExecStart = start;
      # Pas de DynamicUser, pour la même raison que hunyuan3d : le
      # StateDirectory y serait monté noexec (venv inutilisable).
      User = "comfyui";
      Group = "comfyui";
      StateDirectory = "comfyui";
      Restart = "on-failure";
      RestartSec = 30;
      # Premier démarrage = téléchargements de plusieurs dizaines de Go.
      TimeoutStartSec = "infinity";
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];

  users.users.comfyui = {
    isSystemUser = true;
    group = "comfyui";
    home = stateDir;
    extraGroups = [
      "video"
      "render"
    ];
  };
  users.groups.comfyui = { };
}
