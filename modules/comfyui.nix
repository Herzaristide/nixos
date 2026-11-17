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
# dans /var/lib/comfyui/models/<type>/. Tout activé ≈ 240 Go (aujourd'hui : FLUX 3
# Image Klein, Qwen-Image 2.1, Wan 2.2 I2V 14B, YuE 2 et TRELLIS.2 seulement) : le premier
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

  # Seuls FLUX 3 Image Klein, Qwen-Image 2.1, Wan 2.2 I2V 14B, YuE 2 et
  # TRELLIS.2 sont installés pour l'instant (≈ 121 Go avec les annexes Pixal3D / BiRefNet / MoGe et la
  # réécriture de prompt Qwen3.5), choisis d'après les classements de nov. 2026
  # (détail dans le catalogue). FLUX 3 Klein est le seul des modèles d'image
  # installés dont la licence permet un usage commercial (sous 5 M$ de CA) :
  # décommenter une ligne pour ajouter sa famille au prochain rebuild.
  modelGroups = [
    # Images
    # "sd15"
    # "sdxl"
    "zimage"
    # "flux2klein"
    "flux3klein"
    # "flux3kleinbase"
    "qwenimage"
    # "krea2"
    # Vidéo
    # "wan5b"
    "wan14b"
    # "hunyuanvideo"
    # Audio
    # "acestep"
    # "stableaudio"
    "yue"
    # "minimaxmusic"
    # "tts"
    # Outils
    "upscale"
    # "interpolation"
    "vision"
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
        (import ../pkgs/torchvision-rocm.nix { inherit (final) lib rocmPackages symlinkJoin; })
      ];
      # UnwrapMesh (dépliage UV du template TRELLIS.2 / Pixal3D) résout ses
      # cartes LSCM par un torch.linalg.solve fp64 batché sur le GPU ; sur la
      # gfx1102 maquillée, rocSOLVER (getrf batched) y plante — processus tué
      # dès 16 matrices 2048×2048, HIPBLAS_STATUS_ALLOC_FAILED dans ComfyUI
      # (gary, 2026-11-17). Ce solveur passe sur CPU (sa branche numpy existe
      # déjà) ; le reste du dépliage reste sur GPU.
      comfyui = prev.comfyui.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace comfy_extras/mesh3d/uv_unwrap/parameterize.py \
            --replace-fail 'use_gpu = device is not None and device.type == "cuda"' \
                           'use_gpu = device is not None and device.type == "cuda" and torch.version.hip is None'
        '';
      });
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
      # Attention « sub-quadratic » de ComfyUI (PyTorch pur), PAS la SDPA :
      # sur la gfx1102 maquillée en gfx1100, les noyaux AOTriton sont faux
      # (gary, 2026-11-17, mesuré contre une référence exacte) :
      #  - flash : sorties à zéro au-delà de ~64k tokens (49 % de lignes
      #    nulles à 65 536, 80 % à 98 304 ; correct jusqu'à 49 152) ;
      #  - mem-efficient en fp32 : erreur relative ~1e20 à toute longueur.
      # TRELLIS.2 / Pixal3D dépasse largement 64k tokens à l'étape 1024/1536 :
      # latent corrompu → décodage de forme vide (« max(): Expected
      # reduction dim 0 ») ou faute GPU (HSA_STATUS_ERROR_EXCEPTION 0x1016).
      # Avec quad : correct, et plus rapide (étape 1024 : 29 s contre 88 s).
      # Revenir à --use-pytorch-cross-attention seulement après avoir revérifié
      # flash > 64k tokens sur une nouvelle version de torch/aotriton.
      "--use-quad-cross-attention"
      # Pas d'offload asynchrone des poids (activé d'office sur AMD, 2 streams) :
      # avec, Qwen-Image 2.1 bf16 — offloadé à ~88 %, poids streamés vers le
      # GPU à chaque pas — sortait des images corrompues au hasard (bruit,
      # image noire, bandes violettes), le même run tantôt parfait tantôt
      # cassé : course entre streams sous ROCm (gary, 2026-11-17). Sans,
      # 3/3 runs corrects.
      "--disable-async-offload"
      # PAS de --disable-pinned-memory : testé contre FLUX 3 Klein en édition
      # (gris / bruit / noir dès le 2e prompt d'un même processus) — 1/5 runs
      # corrects avec, aucun gain (gary, 2026-11-17).
      # PAS de --cache-none : il corrigeait le second run Qwen-Image au même
      # prompt, mais cassait TRELLIS.2 au hasard (RemeshMesh → maillage vide
      # ou partiel, 3/3 runs ; 2/2 corrects sans) — gary, 2026-11-17.
      # Pas de `--fast fp16_accumulation` : avec, l'encodeur de texte de
      # Qwen-Image (Qwen3-VL 8B, en fp16 sur GPU) sortait un conditionnement
      # faux — images sans rapport avec le prompt, même backend HIP de
      # comfy-kitchen coupé ; correct avec l'encodeur sur CPU (gary, 2026-11-16).
      # Aperçu latent léger pendant l'échantillonnage (interface web).
      "--preview-method"
      "latent2rgb"
      # Ni nœuds d'API payants (Comfy-Org partner nodes) ni pubs en console.
      "--disable-partner-nodes"
      "--disable-product-tips"
      # Cache « pression RAM » (le défaut) : les modèles déjà chargés restent en
      # RAM et ne sont libérés que quand la RAM disponible passe sous ce seuil.
      # Défaut = 10 % de la RAM (~3 Go sur gary), et le seuil n'est vérifié
      # qu'entre deux nœuds : recharger Qwen-Image bf16 (14 Go) avec TRELLIS.2,
      # Pixal3D, YuE et l'encodeur Qwen encore en cache a dépassé les 32 Go en
      # plein chargement → OOM killer (gary, 2026-11-17). 16 Go de marge
      # couvrent le plus gros modèle chargé d'un bloc.
      "--cache-ram"
      "16"
    ];
  };

  systemd.services.comfyui = {
    # Démarré au boot (le défaut du module) : les modèles restent chargés entre
    # deux générations, seule la première après un démarrage paie le
    # chargement (~25 s pour FLUX 3 Klein). Au repos : ~800 Mo de RAM, 0 VRAM.

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
      # les suivantes relisent le CSV. %d = index du GPU, doublé en %%d :
      # systemd développe ses spécificateurs dans Environment= et %d y est le
      # dossier des credentials (le CSV visait /run/credentials/…, illisible).
      PYTORCH_TUNABLEOP_ENABLED = "1";
      PYTORCH_TUNABLEOP_FILENAME = "${stateDir}/tunableop/results%%d.csv";
      # Tuning coupé : sans CSV préexistant, le premier chargement du LoRA
      # Turbo de Qwen-Image a passé 10 min à mesurer des centaines de formes
      # de GEMM (gary, 2026-11-16). Les résultats déjà présents dans le CSV
      # restent lus ; remettre "1" pour une séance de tuning volontaire.
      PYTORCH_TUNABLEOP_TUNING = "0";
      # PAS de PYTORCH_HIP_ALLOC_CONF=expandable_segments:True : sous torch
      # 2.14.1+rocm7.2, l'allocateur à segments extensibles écrase des tenseurs
      # vivants après quelques chargements/déchargements (pytorch#204212).
      # Symptômes sur gary (2026-11-17) : dès le 2e prompt d'un même processus,
      # VAE.encode → 100 % NaN, encodeur de texte → zéros, d'où FLUX 3 Klein en
      # édition gris / bruit / noir, et crashs « Memory access fault … Page not
      # present ». Avec : 2e à 4e prompt corrompus ou crash ; sans : 5/5 puis
      # 8/8 corrects (édition + texte vers image alternés, TunableOp actif).
      # Ne le remettre qu'après avoir revérifié sur une version corrigée.
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
      # Filet de sécurité RAM (gary : 32 Go). Au-delà de MemoryHigh le noyau
      # ralentit le service et lui reprend de la mémoire ; à MemoryMax, l'OOM
      # killer vise ComfyUI seul — sans plafond, un dépassement a tué
      # nix-daemon (2026-11-17). Le swap reste permis au-delà (MemorySwapMax
      # non borné). --cache-ram ci-dessus doit garder le service en dessous.
      MemoryHigh = "24G";
      MemoryMax = "28G";
    };
  };

  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ port ];

  users.users.comfyui.extraGroups = [
    "video"
    "render"
  ];
}
