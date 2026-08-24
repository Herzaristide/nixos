---
title: Accueil
group: Général
summary: Configuration NixOS flake-based gérant quatre hôtes, avec Hyprland, Quickshell et un thème dynamique.
links: [architecture, flake, hosts, build]
---

# Configuration NixOS

Documentation de ma configuration **NixOS flake-based**, qui gère **quatre
machines** à partir d'une source unique : un ordinateur portable, un poste de
travail, un serveur sans écran et un environnement WSL2.

Home-manager est intégré comme module NixOS : un seul `nixos-rebuild` met à jour
le système **et** l'environnement utilisateur en une passe.

## Par où commencer

- 🧭 [Architecture générale](#architecture) — comment les pièces s'assemblent.
- 🧩 [Le flake et ses inputs](#flake) — les briques externes.
- 🖥️ [Les quatre hôtes](#hosts) — zola, gary, kafka, exupery.
- 🛠️ [Build & déploiement](#build) — les commandes du quotidien.

## Points forts

- **Un seul dépôt** pour quatre machines aux profils très différents (Intel+NVIDIA,
  AMD+ROCm, serveur nouveau, WSL2).
- **Option `head`** qui bascule chaque hôte entre profil graphique complet et
  profil serveur — voir [les options transversales](#options).
- **Hyprland** en configuration Lua, **Quickshell** comme shell Wayland, et un
  **daemon d'accent** maison qui propage une couleur unique à toutes les apps
  (voir [Theming](#theming)).
- **Disko + btrfs + LUKS** pour un partitionnement déclaratif reproductible
  (voir [Système de fichiers](#filesystem)).

> Toutes les versions `stateVersion` (système et home) sont figées à **25.11**.
