# Serveur TRELLIS.2 (image → mesh 3D texturé, 4 Md de paramètres) sur le GPU
# ROCm de gary : une instance ComfyUI À PART (port 8189, état dans
# /var/lib/trellis2), indépendante de modules/comfyui.nix qui reste le paquet
# nixpkgs. Piloté comme lui par l'API HTTP de ComfyUI, via Tailscale
# (POST /prompt, GET /history/<id>, GET /view) ; port ouvert sur tailscale0
# seulement.
#
# Pourquoi un module séparé : TRELLIS.2 n'est pas empaquetable proprement. Il
# faut le ComfyUI amont (nœuds personnalisés dans custom_nodes/), des
# extensions HIP compilées sur place (cumesh, flex_gemm, o_voxel, nvdiffrast,
# nvdiffrec_render, custom_rasterizer) et des fichiers de site-packages
# réécrits par le script d'installation. Tout cela vit dans un venv uv, comme
# modules/hunyuan3d.nix, au lieu du ComfyUI en lecture seule de nixpkgs.
#
# Sources figées :
#   - egore/comfyui-trellis2-gguf-rocm @ 0afa00c9 : le script d'installation,
#     écrit pour une RX 7600 XT (gfx1102 en dur, /opt/rocm) — tel quel ici ;
#   - Aero-Ex/ComfyUI-Trellis2-GGUF @ b3b9e951 : le nœud, cloné par ce script
#     (on y ajoute le `git checkout` de cette révision) ;
#   - toastmanAu/trellis-2-rocm-comfyui : patches 05 (BF16) et 06 (sommets
#     infinis) du nœud. Les patches 01 à 04 de ce guide ne servent pas : 01
#     change gfx1102 en gfx1100 (gary EST gfx1102), 02 à 04 règlent un
#     $HOME/--user qu'un venv rend inutiles ;
#   - ComfyUI amont, torch ROCm 7.2 (index PyTorch), kijai/ComfyUI-
#     Hunyuan3DWrapper (custom_rasterizer) : NON figés, pris à l'installation.
#
# PAS de HSA_OVERRIDE_GFX_VERSION ici, contrairement à comfyui.nix et
# hunyuan3d.nix : les extensions sont compilées pour gfx1102, et l'override
# (11.0.0) ferait chercher des kernels gfx1100 qui n'existent pas. Les roues
# torch ROCm 7.2 connaissent la gfx1102.
#
# /opt/rocm : le script le suppose. Il est monté en lecture seule, dans le
# namespace du service, sur `rocmPackages.rocmPath` (clr, hipcc, bibliothèques
# HIP…), pour la compilation des extensions.
#
# Première installation (~20-30 min de compilation, ~15 Go) :
#   sudo systemctl start trellis2 && journalctl -fu trellis2
# Les échecs de compilation HIP sous NixOS sont probables au premier essai (en-
# têtes GL/EGL, toolchain gcc de hipcc…) : ce module est un point de départ,
# pas un montage éprouvé. L'installation ne se rejoue pas tant que le marqueur
# `.installed-<rev>` existe ; après un échec, relancer le service la refait.
# Les poids (GGUF Q4 ≈ 2,5 Go, BF16 ≈ 8 Go) se téléchargent au premier usage.
#
# Pas de démarrage au boot, et jamais en même temps que comfyui/hunyuan3d
# (`conflicts`, symétrique) : un seul modèle à la fois dans les 16 Gio de VRAM.
{ pkgs, lib, ... }:

let
  port = 8189;
  stateDir = "/var/lib/trellis2";

  wrapperRev = "0afa00c92dd90d5dc06419ceca1f50c3ad3b0680";
  nodeRev = "b3b9e951";
  guideRev = "2c93cb946a08b67edcaa0ebaed4a95837f336cc5";

  wrapper = pkgs.fetchFromGitHub {
    owner = "egore";
    repo = "comfyui-trellis2-gguf-rocm";
    rev = wrapperRev;
    hash = "sha256-ZDgk66MhXrXxJRz/AdKuOmgSwxeUDzvRw6HBcd5fNuk=";
  };

  guide = pkgs.fetchFromGitHub {
    owner = "toastmanAu";
    repo = "trellis-2-rocm-comfyui";
    rev = guideRev;
    hash = "sha256-p5W5bxh1+40tSp25kdzKuP4dbXOOh8dWYkfrtIdH8Yk=";
  };

  # Le script d'egore, avec le nœud Aero-Ex figé à la révision que visent les
  # patches 05 et 06.
  installScript = pkgs.runCommand "install-trellis2-gguf-rocm.sh" { } ''
    cp ${wrapper}/install-trellis2-gguf-rocm.sh $out
    chmod +x $out
    substituteInPlace $out --replace-fail \
      'git clone https://github.com/Aero-Ex/ComfyUI-Trellis2-GGUF "$TRELLIS_GGUF"' \
      'git clone https://github.com/Aero-Ex/ComfyUI-Trellis2-GGUF "$TRELLIS_GGUF"
    git -C "$TRELLIS_GGUF" checkout -q ${nodeRev}'
  '';

  # Arborescence /opt/rocm pour hipcc et les en-têtes HIP (aucun méta-paquet
  # SDK dans nixpkgs : `rocmPath` a été supprimé). Chaque composant avec sa
  # sortie `dev` quand elle existe ; un nom absent de cette révision de
  # nixpkgs est ignoré plutôt que de casser l'évaluation.
  rocm = pkgs.symlinkJoin {
    name = "rocm-hip-sdk-trellis2";
    paths = lib.concatMap (p: [ p ] ++ lib.optional (p ? dev) p.dev) (
      lib.filter (p: p != null) (
        map (n: pkgs.rocmPackages.${n} or null) [
          "clr"
          "hipcc"
          "rocm-toolchain"
          "rocm-device-libs"
          "rocm-comgr"
          "rocm-runtime"
          "rocm-core"
          "hipblas"
          "hipblas-common"
          "hipblaslt"
          "rocblas"
          "hipsparse"
          "rocsparse"
          "hipsolver"
          "rocsolver"
          "hipfft"
          "rocfft"
          "hiprand"
          "rocrand"
          "rocprim"
          "hipcub"
          "rocthrust"
          "miopen"
        ]
      )
    );
  };
  python = pkgs.python312;

  # Outils de compilation et d'installation (le script appelle git, curl,
  # sed, find, ss… ; les extensions passent par hipcc → clang, avec le gcc de
  # nixpkgs pour les en-têtes C++ standard).
  buildTools = with pkgs; [
    bash
    coreutils
    findutils
    gnugrep
    gnused
    gawk
    gnumake
    cmake
    ninja
    pkg-config
    gcc
    git
    curl
    patch
    which
    iproute2
    uv
  ];

  # Bibliothèques que les wheels manylinux (opencv, onnxruntime, open3d…) et
  # le rasterizer OpenGL (nvdiffrast → EGL) s'attendent à trouver.
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
    zstd
    xz
    bzip2
    tbb
    libdrm
    "/run/opengl-driver"
  ];

  start = pkgs.writeShellScript "trellis2-start" ''
    set -euo pipefail
    cd ${stateDir}

    if [ ! -x comfy-env/bin/python ]; then
      uv venv --seed --python ${python}/bin/python3 comfy-env
    fi
    # shellcheck disable=SC1091
    source comfy-env/bin/activate

    marker=.installed-${builtins.substring 0 8 wrapperRev}-${nodeRev}
    if [ ! -e "$marker" ]; then
      echo "trellis2: installation (torch ROCm, ComfyUI, extensions HIP)"

      pip install torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/rocm7.2

      if [ ! -d ComfyUI ]; then
        git clone https://github.com/comfyanonymous/ComfyUI.git ComfyUI
      fi
      pip install -r ComfyUI/requirements.txt

      # Le script travaille dans son propre dossier : COMFY_ROOT=$(pwd), avec
      # ./comfy-env (le venv ci-dessus) et ./ComfyUI à côté de lui.
      install -m755 ${installScript} install-trellis2-gguf-rocm.sh
      bash ./install-trellis2-gguf-rocm.sh

      node=ComfyUI/custom_nodes/ComfyUI-Trellis2-GGUF
      patch -d "$node" -p1 < ${guide}/patches/05-model-manager-bf16.patch
      patch -d "$node" -p1 < ${guide}/patches/06-postprocess-infinite-vertices.patch

      # custom_rasterizer, pris dans le dépôt du wrapper Hunyuan3D de kijai.
      rm -rf build-hy3d
      git clone --depth 1 https://github.com/kijai/ComfyUI-Hunyuan3DWrapper.git build-hy3d
      pip install --no-build-isolation \
        build-hy3d/hy3dgen/texgen/custom_rasterizer
      rm -rf build-hy3d

      rm -f .installed-*
      touch "$marker"
    fi

    exec python ComfyUI/main.py \
      --use-pytorch-cross-attention \
      --listen 0.0.0.0 --port ${toString port}
  '';
in
{
  systemd.services.trellis2 = {
    description = "TRELLIS.2 (ComfyUI + nœuds ROCm)";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    conflicts = [
      "comfyui.service"
      "hunyuan3d.service"
    ];
    path = buildTools;

    environment = {
      HOME = stateDir;
      HF_HOME = "${stateDir}/huggingface";
      UV_CACHE_DIR = "${stateDir}/uv-cache";
      UV_PYTHON_DOWNLOADS = "never";
      # Les roues torch ROCm pèsent plusieurs Go : le délai par défaut casse.
      UV_HTTP_TIMEOUT = "300";
      LD_LIBRARY_PATH = lib.makeLibraryPath runtimeLibs;

      # Compilation HIP (le script pose lui-même gfx1102 ; ROCM_HOME est
      # repris tel quel, /opt/rocm étant le montage ci-dessous).
      ROCM_HOME = "/opt/rocm";
      ROCM_PATH = "/opt/rocm";
      # Les extensions compilées en parallèle sans limite saturent la RAM.
      MAX_JOBS = "4";
      # En-têtes et bibliothèques GL/EGL pour le plugin OpenGL de nvdiffrast,
      # que hipcc (clang) ne trouve pas par les wrappers de nixpkgs.
      CPATH = lib.makeSearchPath "include" [
        pkgs.libglvnd.dev
        pkgs.libGL.dev
        pkgs.libx11.dev
        pkgs.xorgproto
      ];
      LIBRARY_PATH = lib.makeLibraryPath [
        pkgs.libglvnd
        pkgs.libGL
      ];

      # Exécution. Pas de HSA_OVERRIDE_GFX_VERSION (voir l'en-tête).
      HIP_VISIBLE_DEVICES = "0";
      ATTN_BACKEND = "sdpa";
      TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL = "1";
      # Contourne HIPBLAS_STATUS_INVALID_VALUE sur RDNA3 (−5 à 10 % sur
      # certains matmuls).
      TORCH_BLAS_PREFER_HIPBLASLT = "0";
      # Pas d'écran sur gary : le rasterizer OpenGL passe par EGL sans
      # surface (Mesa, via /run/opengl-driver).
      EGL_PLATFORM = "surfaceless";
      __EGL_VENDOR_LIBRARY_DIRS = "/run/opengl-driver/share/glvnd/egl_vendor.d";
    };

    serviceConfig = {
      ExecStart = start;
      # Même raison que hunyuan3d : pas de DynamicUser, le StateDirectory y
      # serait monté noexec (venv et .so de torch inutilisables).
      User = "trellis2";
      Group = "trellis2";
      StateDirectory = "trellis2";
      # /opt/rocm : voir l'en-tête. /tmp : le script compile dans
      # /tmp/trellis2-rocm-build, qu'il nettoie lui-même ; un /tmp privé évite
      # les restes d'un échec.
      BindReadOnlyPaths = [ "${rocm}:/opt/rocm" ];
      PrivateTmp = true;
      # Un échec d'installation dure ~30 min : on ne boucle pas dessus.
      Restart = "no";
      TimeoutStartSec = "infinity";
    };
  };

  # Point de montage de /opt/rocm.
  systemd.tmpfiles.rules = [ "d /opt/rocm 0755 root root -" ];

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];

  users.users.trellis2 = {
    isSystemUser = true;
    group = "trellis2";
    home = stateDir;
    extraGroups = [
      "video"
      "render"
    ];
  };
  users.groups.trellis2 = { };
}
