---
title: gary (poste fixe)
group: Hôtes
summary: Poste fixe tout-AMD (Ryzen 7600X + RX 7600 XT), stack ROCm pour le ML.
links: [hosts, options, quirks]
---

# gary — poste fixe tout-AMD

Poste de travail **AMD CPU + AMD GPU**, profil graphique complet (`head = true`).

## Matériel

- **CPU** : AMD Ryzen 5 7600X (Zen 4 / Raphael, AM5, 6c/12t). `amd-pstate` EPP
  automatique, pas de gouverneur forcé.
- **GPU** : Radeon RX 7600 XT (Navi 33 / RDNA3 / `gfx1102`) via `amdgpu`, chargé
  en initrd pour un KMS sans transition. L'iGPU RDNA2 du 7600X (`gfx1036`) est
  aussi piloté par `amdgpu`.

## ROCm (machine learning)

- Stack ROCm : `rocm-smi`, `rocminfo`, `clr`, `rocm-runtime`, `hipcc`.
- Lien tmpfiles `/opt/rocm` → `pkgs.rocmPackages.clr` (chemin de recherche par
  défaut de PyTorch/TF).
- **Mapping d'architecture** : la RX 7600 XT est `gfx1102`, mais rocBLAS amont
  ne fournit que les kernels du flagship `gfx1100`. On expose donc la carte comme
  `gfx1100` via `HSA_OVERRIDE_GFX_VERSION=11.0.0` (system-wide) → rocBLAS trouve
  ses kernels Tensile. **Pas d'overlay custom** : les paquets ROCm viennent tels
  quels du cache binaire Hydra (voir [Points d'attention](#quirks)).
- `services.ollama.package = pkgs.ollama-rocm`.

## RGB

- `services.hardware.openrgb` (carte mère AMD) : contrôle du contrôleur ARGB ITE
  (ventilateurs), souris Corsair, RAM et GPU via SMBus.

## Affichage

- Moniteur principal : `DP-1` (Samsung C27R50x). Voir [Options](#options).
