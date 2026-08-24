---
title: Quickshell
group: Bureau
summary: Le shell Wayland en QML — barre, panneau latéral, chat Ollama, notes, stats.
links: [home-manager, options, hyprland]
---

# Quickshell

**Quickshell** est le shell Wayland : barre inférieure, panneau latéral, chat
Ollama, notes et statistiques matérielles. Il remplace Waybar/DMS.

## Configuration

- Configuré depuis `/quickshell/quickshell.nix` ([home-manager](#home-manager)).
- Tous les fichiers QML vivent dans `/quickshell/` et sont installés en
  lecture seule sous `~/.config/quickshell/`.
- `shell.qml` est **templaté** : `@PRIMARY_MONITOR@` est remplacé par la valeur
  de l'option [`primaryMonitor`](#options) via `builtins.replaceStrings`.

## Lien avec le reste

- Ne s'active que sur les hôtes [`head = true`](#options) ([zola](#zola),
  [gary](#gary)).
- Fonctionne de pair avec [Hyprland](#hyprland) : la barre s'affiche sur le
  moniteur principal, qui reçoit aussi les workspaces 1-5.
- L'input `quickshell` du flake vient de `git.outfoxxed.me` (voir
  [Le flake](#flake)).
