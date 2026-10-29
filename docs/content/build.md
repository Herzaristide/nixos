---
title: Build & déploiement
group: Général
summary: Commandes de rebuild, mise à jour, vérification, formatage et installation.
links: [flake, packages, filesystem]
---

# Build & déploiement

## Reconstruire le système

```bash
# Hôte courant
sudo nixos-rebuild switch --flake .#$(hostname)

# Hôte spécifique
sudo nixos-rebuild switch --flake .#bernanos
```

Home-manager étant intégré comme module NixOS, `nixos-rebuild` met à jour le
système **et** l'environnement utilisateur en une seule passe.

## Mettre à jour les dépendances

```bash
nix flake update        # met à jour tous les inputs (voir Le flake)
```

## Vérifier sans construire

```bash
nix flake check --no-build   # attrape les erreurs d'évaluation à bas coût
```

## Formater les fichiers Nix

```bash
nixfmt **/*.nix
```

## Flux de modification recommandé

1. Éditer le module concerné (ne pas toucher `hardware-configuration.nix`).
2. `nixfmt` les fichiers modifiés.
3. `nix flake check --no-build` pour attraper les erreurs d'éval.
4. `sudo nixos-rebuild switch --flake .#$(hostname)`.
5. Commit avec un sujet court à l'impératif.
