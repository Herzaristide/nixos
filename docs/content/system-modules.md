---
title: Modules système
group: Système
summary: Les modules NixOS partagés du dossier /modules (réseau, énergie, stockage, GUI…).
links: [architecture, options, filesystem, audio, security]
---

# Modules système (`/modules/`)

Les modules partagés qui composent la couche **système** de tous les hôtes.

| Module | Rôle |
| --- | --- |
| `nixos.nix` | Réglages Nix : flakes, GC, `nix-ld`, `system.stateVersion`, plafond de parallélisme de build. |
| `common.nix` | Définit les [options](#options) `head`/`primaryMonitor`/`darkMode` ; locale/clavier FR ; utilisateur `aristide` (immuable, mot de passe hashé) ; docker ; ollama ; câble home-manager dans le système. |
| `network.nix` | NetworkManager + SSH (auth par mot de passe) + pare-feu. |
| `power.nix` | UPower, règles de veille logind, réveil USB. |
| `storage.nix` | RAID mdadm, fstrim, support NTFS, et la liste blanche de montages externes/internes (`/mnt/maxtor`, `/mnt/samsung`, `/mnt/raid`, tous en `nofail`). |
| `head.nix` | Couche GUI : autologin getty (`aristide` sur tty1) → fish exécute directement Hyprland (pas de greeter), portail XDG (hyprland + kde), polices (JetBrains Mono), impression. |
| `audio.nix` | PipeWire, module echo-cancel, règle WirePlumber (voir [Audio](#audio)). |

## À retenir

- **`common.nix` est le pivot** : c'est lui qui définit les [options
  transversales](#options) et intègre home-manager.
- La partie stockage/partitionnement déclaratif est traitée séparément dans
  [Système de fichiers](#filesystem).
- Les aspects utilisateurs/sécurité (mots de passe hashés, sudo) sont détaillés
  dans [Sécurité & utilisateurs](#security).
