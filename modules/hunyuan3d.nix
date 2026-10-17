# Serveur Hunyuan3D-2 (image → mesh 3D) sur le GPU ROCm de gary, consommé par
# l'add-on « MCP for Blender » des autres machines en mode « local api »
# (POST /generate → GLB), via Tailscale : http://gary:8081.
#
# Rien n'est ouvert sur le LAN : le service écoute sur 0.0.0.0 mais seul
# tailscale0 est une interface de confiance (modules/tailscale.nix), et le
# port n'est pas ajouté à allowedTCPPorts.
#
# Tout est figé, sans venir de nixpkgs (torch ROCm n'y est pas en cache) :
#   - le code amont par `rev` (fetchFromGitHub) ;
#   - les dépendances Python par pkgs/hunyuan3d/uv.lock — le venv est
#     synchronisé (`uv sync --frozen`) à chaque démarrage : instantané et
#     hors ligne quand rien n'a changé, incrémental après un `uv lock
#     --upgrade`, recréé si l'interpréteur Nix change ;
#   - les poids par `modelRev` (révision Hugging Face).
# L'état (venv, cache uv, poids, modèle rembg) vit dans /var/lib/hunyuan3d,
# que l'impermanence ne touche pas. Premier démarrage : ~10 Go à télécharger,
# suivre avec `journalctl -fu hunyuan3d`.
#
# Limites :
#   - forme seule : la texture demande les extensions CUDA `custom_rasterizer`
#     et `mesh_processor`, non compilées ici (laisser « Generate Texture »
#     décoché dans Blender) ;
#   - image seule : le text-to-image (HunyuanDiT) est commenté en amont dans
#     api_server.py, une requête texte seule échoue.
{ pkgs, lib, ... }:

let
  port = 8081;
  stateDir = "/var/lib/hunyuan3d";

  # Branche main de Tencent-Hunyuan/Hunyuan3D-2, 2025-10-28.
  src = pkgs.fetchFromGitHub {
    owner = "Tencent-Hunyuan";
    repo = "Hunyuan3D-2";
    rev = "f8db63096c8282cb27354314d896feba5ba6ff8a";
    hash = "sha256-tbPuhnCqUcSnttdTs/DxcYLQWterNlbWyNqTHmUxcOs=";
  };

  # Modèle par défaut d'api_server.py : DiT mini-turbo + son VAE turbo
  # (chargé par enable_flashvdm). hy3dgen cherche d'abord sous
  # $HY3DGEN_MODELS/<repo>/<subfolder>, où on les dépose à cette révision.
  modelRepo = "tencent/Hunyuan3D-2mini";
  modelRev = "f90a0f7df7d5e6f71109cf333f6a95a0ae3194a6"; # 2025-10-17
  modelSubfolders = [
    "hunyuan3d-dit-v2-mini-turbo"
    "hunyuan3d-vae-v2-mini-turbo"
  ];

  project = builtins.path {
    name = "hunyuan3d-project";
    path = ../pkgs/hunyuan3d;
  };

  python = pkgs.python312;

  # Bibliothèques que les wheels manylinux (opencv, pymeshlab, onnxruntime…)
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
  ];

  start = pkgs.writeShellScript "hunyuan3d-start" ''
    set -euo pipefail
    cd ${stateDir}

    ${lib.getExe pkgs.uv} sync --frozen --project ${project} --python ${python}/bin/python3

    if [ ! -e models/.rev-${modelRev} ]; then
      echo "hunyuan3d: téléchargement de ${modelRepo}@${modelRev}"
      venv/bin/hf download ${modelRepo} --revision ${modelRev} \
        --local-dir models/${modelRepo} \
        --include ${lib.concatMapStringsSep " " (s: "'${s}/*'") modelSubfolders}
      rm -f models/.rev-*
      touch models/.rev-${modelRev}
    fi

    # api_server.py écrit son cache (gradio_cache/) et ses logs dans le cwd.
    HF_HUB_OFFLINE=1 exec venv/bin/python ${src}/api_server.py \
      --host 0.0.0.0 --port ${toString port} --device cuda \
      --model_path ${modelRepo}
  '';
in
{
  systemd.services.hunyuan3d = {
    description = "Hunyuan3D-2 API server (ROCm)";
    wantedBy = [ "multi-user.target" ];
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];

    environment = {
      HOME = stateDir;
      HF_HOME = "${stateDir}/huggingface";
      HY3DGEN_MODELS = "${stateDir}/models";
      U2NET_HOME = "${stateDir}/u2net";
      UV_CACHE_DIR = "${stateDir}/uv-cache";
      UV_PROJECT_ENVIRONMENT = "${stateDir}/venv";
      UV_PYTHON_DOWNLOADS = "never";
      # Le wheel torch ROCm fait 4 Go : le délai par défaut (30 s) casse.
      UV_HTTP_TIMEOUT = "300";
      PYTHONPATH = "${src}";
      LD_LIBRARY_PATH = lib.makeLibraryPath runtimeLibs;
      # Même mapping gfx1102 → gfx1100 que la variable système de gary, que
      # les services ne voient pas (environment.variables = sessions seules).
      HSA_OVERRIDE_GFX_VERSION = "11.0.0";
    };

    serviceConfig = {
      ExecStart = start;
      DynamicUser = true;
      StateDirectory = "hunyuan3d";
      SupplementaryGroups = [
        "video"
        "render"
      ];
      Restart = "on-failure";
      RestartSec = 30;
      # Premier démarrage = téléchargements de plusieurs Go.
      TimeoutStartSec = "infinity";
    };
  };
}
