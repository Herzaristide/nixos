---
title: kafka (serveur)
group: Hôtes
summary: Serveur sans écran, Intel + NVS 310 (nouveau), UEFI systemd-boot, disko dédié.
links: [hosts, filesystem, options]
---

# kafka — serveur sans écran

Serveur **headless**, profil serveur (`head = false`).

## Matériel

- **CPU** : Intel (`kvm-intel`, microcode Intel mis à jour).
- **GPU** : NVIDIA NVS 310 (Fermi / GF119) — trop ancienne pour le pilote
  propriétaire actuel ; utilise le **nouveau in-tree** pour une console KMS
  propre. Aucune stack graphique.

## Boot & stockage

- Boot **UEFI via systemd-boot** (pas de GRUB).
- Particularité disko : le firmware du T3610 ne sait pas booter le NVMe, donc
  kafka a son **propre `hosts/kafka/disko.nix`** — l'ESP est sur une clé USB
  (relais de boot), le NVMe reste LUKS + btrfs.
- Layout btrfs identique aux autres hôtes UEFI (`@`, `@home`, `@nix`) — voir
  [Système de fichiers](#filesystem).

## Profil

Comme `head = false`, kafka ne charge que les modules CLI/serveur (pas de
Hyprland, Quickshell ni thème). Voir [Options transversales](#options).
