---
title: Options transversales
group: Système
summary: Les options head, primaryMonitor et darkMode qui pilotent le comportement des hôtes.
links: [system-modules, hosts, home-manager, quickshell, theming]
---

# Options transversales

Trois options déclarées dans `modules/common.nix` pilotent l'essentiel du
comportement d'un hôte.

## `head` (bool, défaut `false`)

Bascule chaque machine entre profil serveur et profil graphique complet.

- **`head = true`** ([gary](#gary), [zola](#zola)) — tire `modules/head.nix` et
  les modules home-manager graphiques : [Hyprland](#hyprland),
  [Quickshell](#quickshell), thème/accent, KDE/Qt, chromium, alacritty…
- **`head = false`** ([exupery](#exupery), [kafka](#kafka)) — uniquement les
  modules CLI/serveur.

## `primaryMonitor` (string, défaut `HDMI-A-1`)

Sortie Hyprland qui reçoit les workspaces 1-5 et la barre Quickshell.

- [zola](#zola) surcharge en `eDP-1`, [gary](#gary) utilise `DP-1`.
- La valeur est **consommée par [Quickshell](#quickshell)** : la changer réécrit
  `~/.config/quickshell/shell.qml` (le motif `@PRIMARY_MONITOR@` est remplacé
  via `builtins.replaceStrings`).

## `darkMode` (bool, défaut `true`)

Pilote le schéma de couleurs diffusé à dconf, GTK, Qt et aux valeurs par défaut
du [daemon d'accent](#theming).

---

En pratique, adapter un hôte revient le plus souvent à ajuster ces trois options
plutôt qu'à dupliquer de la configuration (voir [Architecture](#architecture)).
