---
title: exupery (WSL2)
group: Hôtes
summary: Environnement de développement sans écran sous WSL2.
links: [hosts, flake, options]
---

# exupery — WSL2

Environnement de **développement headless** sous WSL2 (`head = false`).

## Spécificités

- Importe `nixos-wsl.nixosModules.default`, avec `wsl.enable = true`
  (voir l'input `nixos-wsl` dans [Le flake](#flake)).
- **Pas de bootloader**, **pas de disko** : le système de fichiers est géré par
  WSL.
- NetworkManager désactivé : utilise le réseau de l'hôte Windows.
- Variables SSL positionnées globalement (contextes de certificats
  d'entreprise) ; `GIT_SSL_NO_VERIFY=true` est intentionnel.

Comme les autres hôtes serveur, exupery ne charge que les modules CLI/dév — voir
[Options transversales](#options).
