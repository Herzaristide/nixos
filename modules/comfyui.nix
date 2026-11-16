# Serveur ComfyUI (images, vidéo, audio, 3D) sur le GPU ROCm de gary, piloté
# par Claude Code via son API HTTP (Tailscale) : POST /prompt,
# GET /history/<id>, GET /view. Plus de Krita (retiré 2026-11-13) : les images
# se régénèrent plutôt qu'elles ne se retouchent.
#
# Le paquet `comfyui` et le module `services.comfyui` viennent de nixpkgs (en
# cache), à une exception près : comfy-kitchen est recompilé avec son backend
# HIP (pkgs/comfy-kitchen-hip.nix). torch est la variante ROCm parce que gary
# pose `nixpkgs.config.rocmSupport` (hosts/gary/configuration.nix).
#
# Modèles : catalogue figé dans modules/comfyui-models.nix, un groupe par
# famille ; `modelGroups` ci-dessous choisit lesquels sont installés. Le
# module les télécharge dans le store Nix (fetchurl, hash vérifié) et les lie
# dans /var/lib/comfyui/models/<type>/. Tout activé ≈ 240 Go (aujourd'hui : Qwen-Image
# 2.1, YuE 2 et TRELLIS.2 seulement) : le premier
# `nixos-rebuild` les télécharge tous, retirer un groupe libère sa place au
# prochain `nix-collect-garbage`. Les fichiers déposés à la main dans
# models/ ne sont pas touchés.
#
# État dans /var/lib/comfyui (images, base sqlite, caches de tuning), que
# l'impermanence ne touche pas.
#
# Pas de démarrage au boot : chargé, un modèle occupe l'essentiel des 16 Gio
# de la RX 7600 XT. On le lance à la main : `sudo systemctl start
# comfyui`, puis `stop` après usage. Rien n'est ouvert sur le LAN : le service
# écoute sur 0.0.0.0 mais le port n'est ouvert que sur tailscale0.
{ lib, ... }:

let
  port = 8188;
  stateDir = "/var/lib/comfyui";

  catalogue = import ./comfyui-models.nix;

  # Seuls Qwen-Image 2.1, YuE 2 et TRELLIS.2 sont installés pour l'instant
  # (≈ 48 Go), choisis d'après les classements de nov. 2026 (détail dans le
  # catalogue) :
  # décommenter une ligne pour ajouter sa famille au prochain rebuild.
  modelGroups = [
    # Images
    # "sd15"
    # "sdxl"
    # "zimage"
    # "flux2klein"
    "qwenimage"
    # "krea2"
    # Vidéo
    # "wan5b"
    # "wan14b"
    # "hunyuanvideo"
    # Audio
    # "acestep"
    # "stableaudio"
    "yue"
    # "minimaxmusic"
    # "tts"
    # Outils
    # "upscale"
    # "interpolation"
    # "vision"
    # 3D
    "trellis2"
  ];
in
{
  # Backend HIP de comfy-kitchen (GEMM int8/w4a8 WMMA, RoPE, conversions fp8)
  # au lieu du seul backend PyTorch générique de nixpkgs.
  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (import ../pkgs/comfy-kitchen-hip.nix { inherit (final) lib rocmPackages symlinkJoin; })
      ];
    })
  ];

  services.comfyui = {
    enable = true;
    inherit port;
    listen = [ "0.0.0.0" ];

    # Un même fichier (qwen_3_4b, umt5_xxl…) sert plusieurs groupes, parfois
    # depuis deux dépôts (URL différentes, même hash) : une seule entrée par
    # chemin models/<type>/<nom>, sinon le `ln -sn` du module échoue sur le
    # second lien et le service ne démarre pas.
    models = lib.attrValues (
      lib.listToAttrs (
        map (m: lib.nameValuePair "${m.installPaths}/${m.name}" m) (
          lib.concatMap (g: catalogue.${g}) modelGroups
        )
      )
    );

    extraArgs = [
      # Attention SDPA de PyTorch (flash / mem-efficient via AOTriton).
      # ComfyUI l'active déjà seul pour une carte vue comme gfx1100 ; le dire
      # explicitement la garde si l'override HSA saute un jour (gfx1102 n'est
      # pas dans sa liste et retomberait sur la split attention, plus lente).
      "--use-pytorch-cross-attention"
      # Accumulation fp16 dans les matmuls (WMMA RDNA3 : débit doublé contre
      # une précision moindre). Marquée « peut dégrader la qualité » en amont ;
      # la retirer si des images sortent bruitées ou noires.
      "--fast"
      "fp16_accumulation"
      # Aperçu latent léger pendant l'échantillonnage (interface web).
      "--preview-method"
      "latent2rgb"
      # Ni nœuds d'API payants (Comfy-Org partner nodes) ni pubs en console.
      "--disable-partner-nodes"
      "--disable-product-tips"
    ];
  };

  systemd.services.comfyui = {
    # Le module démarre le service au boot ; ici, à la main seulement.
    wantedBy = lib.mkForce [ ];

    environment = {
      # Même mapping gfx1102 → gfx1100 que la variable système de gary, que
      # les services ne voient pas (environment.variables = sessions seules).
      HSA_OVERRIDE_GFX_VERSION = "11.0.0";
      # torch voit aussi l'iGPU Raphael (gfx1036, maquillé en gfx1100 par
      # l'override ci-dessus) en cuda:1 ; on ne garde que la RX 7600 XT.
      HIP_VISIBLE_DEVICES = "0";
      # Sans ça, torch ROCm n'a ni flash ni mem-efficient attention sur RDNA3
      # et retombe sur la SDPA « math », qui matérialise la matrice
      # d'attention (plusieurs Gio de plus, OOM HIP sur les grandes images).
      TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL = "1";
      # Les solveurs MIOpen « Winograd Fury » sont des binaires précompilés
      # pour la vraie gfx1100 : sur la gfx1102 maquillée par l'override, ils
      # font tomber la file GPU (HSA_STATUS_ERROR_INVALID_ISA, « Illegal
      # opcode » côté noyau). Seules les convolutions fp16 les choisissent
      # (les VAE). MIOpen retombe alors sur ConvBinWinogradRxSf2x3g1.
      # (ComfyUI coupe MIOpen par défaut sur RDNA3 — torch.backends.cudnn —
      # sauf COMFYUI_ENABLE_MIOPEN=1 ; ces deux variables restent pour ce cas.)
      MIOPEN_DEBUG_AMD_WINOGRAD_FURY_RXS_F2X3 = "0";
      MIOPEN_DEBUG_AMD_WINOGRAD_FURY_RXS_F3X2 = "0";

      # TunableOp : PyTorch mesure plusieurs noyaux hipBLASLt/rocBLAS pour
      # chaque forme de GEMM rencontrée et garde le plus rapide. Les premières
      # générations d'un nouveau modèle/résolution sont plus lentes (tuning),
      # les suivantes relisent le CSV. %d = index du GPU.
      PYTORCH_TUNABLEOP_ENABLED = "1";
      PYTORCH_TUNABLEOP_FILENAME = "${stateDir}/tunableop/results%d.csv";
      # Segments extensibles : moins de fragmentation du tas HIP, donc moins
      # d'OOM quand ComfyUI charge et décharge des modèles de tailles variées.
      PYTORCH_HIP_ALLOC_CONF = "expandable_segments:True";
      # Arguments de noyau en mémoire GPU plutôt qu'hôte : latence de
      # lancement réduite (recommandation AMD pour l'inférence sur RDNA).
      HIP_FORCE_DEV_KERNARG = "1";
      # Caches de noyaux compilés (MIOpen, Triton) dans l'état persistant
      # plutôt que sous un $HOME que ProtectHome masque.
      MIOPEN_USER_DB_PATH = "${stateDir}/cache/miopen";
      MIOPEN_CUSTOM_CACHE_DIR = "${stateDir}/cache/miopen";
      TRITON_CACHE_DIR = "${stateDir}/cache/triton";
    };

    preStart = lib.mkAfter ''
      mkdir -p ${stateDir}/tunableop ${stateDir}/cache/miopen ${stateDir}/cache/triton
    '';

    serviceConfig = {
      # Le module met PrivateUsers = true : les groupes video/render, qui
      # donnent accès à /dev/kfd et /dev/dri, y seraient vus comme « nogroup ».
      PrivateUsers = lib.mkForce false;
      # Le déchargement des poids en RAM passe par de la mémoire épinglée
      # (pinned) pour des copies asynchrones ; pas de plafond memlock qui
      # pourrait la limiter.
      LimitMEMLOCK = "infinity";
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];

  users.users.comfyui.extraGroups = [
    "video"
    "render"
  ];
}
