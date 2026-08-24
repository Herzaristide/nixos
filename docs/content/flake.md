---
title: Le flake
group: Général
summary: Inputs du flake et sorties (nixosConfigurations, homeConfigurations, packages).
links: [architecture, build, filesystem, packages]
---

# Le flake

`flake.nix` est le point d'entrée : il déclare les dépendances externes
(**inputs**) et construit les systèmes (**outputs**).

## Inputs

| Input | Source | Rôle |
| --- | --- | --- |
| `nixpkgs` | `nixos-unstable` | Canal principal des paquets. |
| `home-manager` | nix-community | Environnement utilisateur, intégré comme module NixOS. |
| `nixos-wsl` | nix-community | Support WSL2 (hôte [exupery](#exupery)). |

| `quickshell` | git.outfoxxed.me | Shell Wayland (voir [Quickshell](#quickshell)). |
| `karenine` | `github:Herzaristide/karenine` | Projet personnel intégré. |
| `disko` | nix-community | Partitionnement déclaratif (voir [Système de fichiers](#filesystem)). |

Tous les inputs suivent `nixpkgs` (`inputs.nixpkgs.follows`) pour éviter la
duplication de versions.

## Outputs

- **`nixosConfigurations`** — un système par hôte : `zola`, `gary`, `kafka`,
  `exupery`. Chaque hôte reçoit `nixpkgs.hostPlatform = x86_64-linux`, le module
  disko partagé (sauf [kafka](#kafka), qui a son propre `disko.nix`), et sa
  `configuration.nix`.
- **`homeConfigurations.aristide`** — une configuration home-manager
  autonome (utilisable sur une machine non-NixOS, utilisateur `apichere`),
  en `head = false`.
- **`packages.x86_64-linux.paletted`** — le [daemon d'accent](#theming).

## Rebuild

```bash
sudo nixos-rebuild switch --flake .#$(hostname)
```

Les commandes complètes sont dans [Build & déploiement](#build).
