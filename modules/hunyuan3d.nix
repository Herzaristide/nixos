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
# Pas de démarrage au boot : le serveur occupe ~18 Gio de RAM (poids chargés
# côté CPU en plus du GPU) et ~12 Gio de VRAM, de quoi gêner les agents de
# gary. On le lance à la main : `sudo systemctl start hunyuan3d`, puis `stop`
# après usage.
#
# Limite : forme seule — la texture demande les extensions CUDA
# `custom_rasterizer` et `mesh_processor`, non compilées ici (laisser
# « Generate Texture » décoché dans Blender). Le texte seul passe par
# HunyuanDiT (text → image → mesh), réactivé ci-dessous.
{ pkgs, lib, ... }:

let
  port = 8081;
  stateDir = "/var/lib/hunyuan3d";

  # Branche main de Tencent-Hunyuan/Hunyuan3D-2, 2025-10-28.
  src = pkgs.applyPatches {
    name = "hunyuan3d-src";
    src = pkgs.fetchFromGitHub {
      owner = "Tencent-Hunyuan";
      repo = "Hunyuan3D-2";
      rev = "f8db63096c8282cb27354314d896feba5ba6ff8a";
      hash = "sha256-tbPuhnCqUcSnttdTs/DxcYLQWterNlbWyNqTHmUxcOs=";
    };
    # Réactive le text-to-image (HunyuanDiT), commenté en amont : les 4
    # lignes du pipeline_t2i dans Hunyuan3DDiTFlowMatchingPipeline.__init__.
    postPatch = ''
      sed -i \
        -e "s|^\(\s*\)# self.pipeline_t2i = HunyuanDiTPipeline(|\1self.pipeline_t2i = HunyuanDiTPipeline(|" \
        -e "s|^\(\s*\)#     'Tencent-Hunyuan/HunyuanDiT-v1.1-Diffusers-Distilled',|\1    '${t2iRepo}',|" \
        -e "s|^\(\s*\)#     device=device|\1    device=device|" \
        -e "s|^\(\s*\)# )$|\1)|" \
        api_server.py
    '';
  };

  # Text-to-image : HunyuanDiT distillé (fp16, ~10 Go avec le texte encodeur
  # mT5), chargé en plus de la forme sur le GPU.
  t2iRepo = "Tencent-Hunyuan/HunyuanDiT-v1.1-Diffusers-Distilled";

  # Modèle par défaut d'api_server.py : DiT mini-turbo + son VAE turbo
  # (chargé par enable_flashvdm). hy3dgen cherche d'abord sous
  # $HY3DGEN_MODELS/<repo>/<subfolder>, où on les dépose à cette révision.
  # Chaque poids existe en .ckpt et en .safetensors ; api_server.py passe
  # use_safetensors=True, on ne prend donc que ces derniers (~4 Go de moins).
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
    # torch / triton
    zstd
    xz
    bzip2
    # pymeshlab
    e2fsprogs # libcom_err
    fontconfig
    freetype
    gmp
    libgpg-error
    p11-kit
    # numba (parallélisme TBB)
    tbb
  ];

  start = pkgs.writeShellScript "hunyuan3d-start" ''
    set -euo pipefail
    cd ${stateDir}

    ${lib.getExe pkgs.uv} sync --frozen --project ${project} --python ${python}/bin/python3

    if [ ! -e models/.rev-${modelRev} ]; then
      echo "hunyuan3d: téléchargement de ${modelRepo}@${modelRev}"
      venv/bin/hf download ${modelRepo} --revision ${modelRev} \
        --local-dir models/${modelRepo} \
        --include ${
          lib.concatMapStringsSep " " (s: "'${s}/config.yaml' '${s}/*.safetensors'") modelSubfolders
        }
      rm -f models/.rev-*
      touch models/.rev-${modelRev}
    fi

    # HunyuanDiT passe par diffusers : cache HF standard (HF_HOME), pas models/.
    # Sans effet une fois les poids en cache ; hors ligne ensuite.
    venv/bin/hf download ${t2iRepo}

    # api_server.py écrit son cache (gradio_cache/) et ses logs dans le cwd.
    HF_HUB_OFFLINE=1 exec venv/bin/python ${src}/api_server.py \
      --host 0.0.0.0 --port ${toString port} --device cuda \
      --model_path ${modelRepo}
  '';
in
{
  systemd.services.hunyuan3d = {
    description = "Hunyuan3D-2 API server (ROCm)";
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
      # torch voit aussi l'iGPU Raphael (gfx1036, maquillé en gfx1100 par
      # l'override ci-dessus) en cuda:1 ; on ne garde que la RX 7600 XT.
      HIP_VISIBLE_DEVICES = "0";
      # Sans ça, torch ROCm n'a ni flash ni mem-efficient attention sur RDNA3
      # et retombe sur la SDPA « math », qui matérialise la matrice
      # d'attention : HunyuanDiT (4096 tokens) demandait 3 Gio de plus et
      # sortait en OOM HIP à côté des ~12 Gio des deux pipelines.
      TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL = "1";
    };

    serviceConfig = {
      ExecStart = start;
      # Pas de DynamicUser : systemd 261 monte alors le StateDirectory
      # (/var/lib/private/hunyuan3d, bind idmappé) en noexec dans le
      # namespace du service — `venv/bin/hf` sortait en « Permission denied »
      # (126), et les .so de torch n'auraient pas pu être mappés exécutables.
      # En quittant DynamicUser, systemd ramène le répertoire de
      # /var/lib/private vers /var/lib mais ne le rechown pas : sur disque,
      # l'idmapping laissait tout à nobody (65534), d'où un
      # `chown -R hunyuan3d:hunyuan3d /var/lib/hunyuan3d` manuel (2026-10-17).
      User = "hunyuan3d";
      Group = "hunyuan3d";
      StateDirectory = "hunyuan3d";
      Restart = "on-failure";
      RestartSec = 30;
      # Premier démarrage = téléchargements de plusieurs Go.
      TimeoutStartSec = "infinity";
    };
  };

  users.users.hunyuan3d = {
    isSystemUser = true;
    group = "hunyuan3d";
    home = stateDir;
    extraGroups = [
      "video"
      "render"
    ];
  };
  users.groups.hunyuan3d = { };
}
