---
title: wsl (WSL2)
group: Hôtes
summary: Environnement de développement sans écran sous WSL2.
links: [hosts, flake, options]
---

# wsl — WSL2

Environnement de **développement headless** sous WSL2 (`head = false`).

## Spécificités

- Importe `nixos-wsl.nixosModules.default`, avec `wsl.enable = true`
  (voir l'input `nixos-wsl` dans [Le flake](#flake)).
- **Pas de bootloader**, **pas de disko** : le système de fichiers est géré par
  WSL.
- NetworkManager désactivé : utilise le réseau de l'hôte Windows.
- Variables SSL positionnées globalement (contextes de certificats
  d'entreprise) ; aucune vérification TLS n'est désactivée.

Comme les autres hôtes serveur, wsl ne charge que les modules CLI/dév — voir
[Options transversales](#options).
