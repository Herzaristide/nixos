---
title: Les hôtes
group: Hôtes
summary: Vue d'ensemble des quatre machines gérées par la configuration.
links: [zola, gary, kafka, exupery, options]
---

# Les hôtes

La configuration gère **quatre machines** aux profils très différents. Chacune a
son dossier `hosts/<hostname>/` (`configuration.nix` + `hardware-configuration.nix`).

| Hôte | Type | CPU / GPU | Profil |
| --- | --- | --- | --- |
| [zola](#zola) | Portable | Intel + NVIDIA (hybride, Prime offload) | Graphique complet |
| [gary](#gary) | Poste fixe | AMD Ryzen 5 7600X + Radeon RX 7600 XT (ROCm) | Graphique complet |
| [kafka](#kafka) | Serveur | Intel + NVIDIA NVS 310 (nouveau) | Sans écran |
| [exupery](#exupery) | WSL2 | — | Dév sans écran |

## Ce qui distingue un hôte

Le gros du comportement tient à l'option [`head`](#options) :

- `head = true` (zola, gary) → couche graphique complète : [Hyprland](#hyprland),
  [Quickshell](#quickshell), [thème](#theming), chromium, alacritty…
- `head = false` (kafka, exupery) → uniquement les modules CLI/serveur.

Un hôte ne contient donc que le strict spécifique : GPU, bootloader, gestion de
l'énergie et moniteur principal.
