---
title: Système de fichiers
group: Système
summary: Partitionnement déclaratif avec disko — GPT + LUKS2 + btrfs sur les hôtes UEFI.
links: [flake, kafka, system-modules, build]
---

# Système de fichiers (disko)

Tous les hôtes UEFI partagent un **layout disko unique** dans `modules/disko.nix`
(importé par [le flake](#flake)).

## Layout

- **Hôtes UEFI** ([zola](#zola), [gary](#gary), [kafka](#kafka)) :
  GPT + ESP (FAT32, `/boot`, `fmask=0077`/`dmask=0077`) + LUKS2
  (`allowDiscards=true`) → **btrfs** sur `/dev/nvme0n1`.
- **Hôte WSL** ([exupery](#exupery)) : pas de disko, pas de bootloader.

## Sous-volumes btrfs

`@` (`/`), `@home` (`/home`), `@nix` (`/nix`) — tous persistants.

Options de montage :

```
compress=zstd noatime space_cache=v2 discard=async ssd
```

## Cibler un autre disque

Sur un futur hôte, surcharger dans sa `configuration.nix` :

```nix
disko.devices.disk.main.device = lib.mkForce "/dev/…";
```

## Cas particulier : kafka

Le firmware du Dell T3610 ne sait pas booter le NVMe. [kafka](#kafka) a donc son
**propre `disko.nix`** : l'ESP est déportée sur une clé USB (relais de boot), le
NVMe restant en LUKS + btrfs.

## Installation

La passphrase LUKS est lue depuis `/tmp/disko-luks-passphrase` pendant l'install
— écrire ce fichier avant de lancer disko, ou le passer via
`nixos-anywhere --extra-files`. Voir [Build & déploiement](#build).
