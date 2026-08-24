---
title: Paquets custom
group: Système
summary: Les paquets maison exposés par le flake — install-nixos et paletted.
links: [flake, theming, build]
---

# Paquets custom

Exposés sous `packages.x86_64-linux` par [le flake](#flake).

## `install-nixos`

Clone le flake dans `/etc/nixos`, régénère `hardware-configuration.nix`, puis
lance `nixos-rebuild`. Point d'entrée : `install.sh`.

```bash
nix run .#install-nixos -- <git-url> <hostname>
```

Voir [Build & déploiement](#build) pour le contexte d'installation.

## `paletted`

Alias du [daemon d'accent](#theming) (`accent-daemon`). Fournit les binaires
`paletted` (rendu de templates) et `palette` (CLI de couleur).
