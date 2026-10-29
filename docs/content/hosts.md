---
title: Les hôtes
group: Hôtes
summary: Vue d'ensemble des cinq machines gérées par la configuration.
links: [bernanos, exupery, gary, kafka, wsl, options]
---

# Les hôtes

La configuration gère **cinq machines** aux profils très différents. Chacune a
son dossier `hosts/<hostname>/` (`configuration.nix` + `hardware-configuration.nix`).

| Hôte | Type | CPU / GPU | Profil |
| --- | --- | --- | --- |
| [bernanos](#bernanos) | Portable | Intel + NVIDIA (hybride, Prime offload) | Graphique complet |
| [gary](#gary) | Poste fixe | AMD Ryzen 5 7600X + Radeon RX 7600 XT (ROCm) | Graphique complet |
| [kafka](#kafka) | Serveur | Intel + NVIDIA NVS 310 (nouveau) | Sans écran |
| [exupery](#exupery) | 2-en-1 | Intel UHD 620 | Graphique complet + tablette |
| [wsl](#wsl) | WSL2 | — | Dév sans écran |

## Ce qui distingue un hôte

Le gros du comportement tient à l'option [`head`](#options) :

- `head = true` (bernanos, exupery) → couche graphique complète : [Hyprland](#hyprland),
  [Quickshell](#quickshell), [thème](#theming), chromium, alacritty…
- `head = false` (gary, kafka, wsl) → uniquement les modules CLI/serveur.

Un hôte ne contient donc que le strict spécifique : GPU, bootloader, gestion de
l'énergie et moniteur principal.
