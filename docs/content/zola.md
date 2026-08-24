---
title: zola (portable)
group: Hôtes
summary: Portable Intel + NVIDIA hybride, Prime offload, profil graphique complet.
links: [hosts, hyprland, options, quirks]
---

# zola — portable Intel + NVIDIA

Ordinateur portable en **graphique hybride** Intel + NVIDIA, profil graphique
complet (`head = true`).

## GPU & Wayland

- Pilote NVIDIA **propriétaire** (`open = false`), **Prime offload** : l'iGPU
  Intel est utilisé par défaut, le NVIDIA à la demande via `nvidia-offload <cmd>`.
- Variables d'environnement Wayland/NVIDIA :
  - `GBM_BACKEND=nvidia-drm`
  - `WLR_NO_HARDWARE_CURSORS=1` — **obligatoire** : la désactiver tue le curseur
    sous Wayland (voir [Points d'attention](#quirks)).
  - `LIBVA_DRIVER_NAME=iHD` — décodage vidéo Chrome sur l'iGPU Intel (évite les
    bugs de nvidia-vaapi).

## Énergie

- `services.auto-cpufreq` + `thermald` + `powertop` pour la gestion d'énergie
  du portable.

## IA locale

- `services.ollama.package = pkgs.ollama-cuda`, avec `__NV_PRIME_RENDER_OFFLOAD`
  explicite pour que le service systemd d'ollama utilise le dGPU.
- Cachix : `cuda-maintainers.cachix.org`.

## Affichage

- Moniteur principal : `eDP-1` (écran intégré) — surcharge la valeur par défaut
  `HDMI-A-1` (voir [Options transversales](#options)).
- Script `hypr-closed-lid-layout` : quand le capot est fermé et qu'un écran
  externe est présent, déplace les workspaces 1-5 vers `HDMI-A-1` et désactive
  `eDP-1` (voir [Hyprland](#hyprland)).
