---
title: Points d'attention
group: Système
summary: Les pièges à connaître — NVIDIA, ROCm, Hyprland Lua, VSCode headless.
links: [zola, gary, hyprland, home-manager]
---

# Points d'attention

Les subtilités à garder en tête avant de modifier la config.

1. **NVIDIA sur [zola](#zola)** : `WLR_NO_HARDWARE_CURSORS=1` est obligatoire —
   la désactiver tue le curseur sous Wayland.
2. **ROCm sur [gary](#gary)** : ne pas réintroduire d'overlay `gpuTargets`.
   rocBLAS amont a déjà `gfx1100`, et on y mappe la RX 7600 XT (`gfx1102`) via
   `HSA_OVERRIDE_GFX_VERSION=11.0.0`. Tout overlay touchant `gpuTargets` diverge
   du cache Hydra et déclenche ~30 min de régénération des kernels Tensile.
3. **VSCode** : hôtes headless → `vscode-server.nix` (attach SSH distant) ;
   hôtes headful → `vscode/vscode.nix`. Câblés automatiquement par
   `home/home.nix` (voir [Home-manager](#home-manager)).
4. **Config Lua d'[Hyprland](#hyprland)** : `home/modules/hyprland.nix` génère du
   Lua, pas le format `hypr.conf` classique. Utiliser `mkLuaInline` pour du Lua
   brut, des attribute sets pour le reste.
5. **`primaryMonitor` est consommé par [Quickshell](#quickshell)** : changer la
   valeur réécrit `~/.config/quickshell/shell.qml`.
6. **Avertissement mdadm à l'éval** (`Neither MAILADDR nor PROGRAM has been set`)
   est bénin — définir `boot.swraid.mdadmConf` pour le faire taire.
