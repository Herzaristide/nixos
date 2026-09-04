---
title: Home-manager
group: Système
summary: L'environnement utilisateur du dossier /home — shell, éditeurs, GUI.
links: [architecture, options, hyprland, quickshell, theming]
---

# Home-manager (`/home/`)

Home-manager est **intégré comme module NixOS** : `nixos-rebuild` met à jour
l'environnement utilisateur en même temps que le système.

## Points d'entrée

- `home.nix` — importe inconditionnellement les modules headless
  (network/shell/code) ; ajoute les modules graphiques quand
  [`head = true`](#options). Définit `EDITOR=micro`, `BROWSER=chromium`,
  `TERMINAL=alacritty`.
- `head.nix` — couche utilisateur GUI : dconf (color-scheme), thème du curseur,
  rafraîchissement du cache fontconfig, applications MIME par défaut, entrée
  desktop `file-explorer`.

## Modules

- `modules/hyprland.nix` — [Hyprland](#hyprland) en mode Lua, keybinds,
  moniteurs, workspaces spéciaux.
- `modules/alacritty.nix` — configuration du terminal.
- `modules/hyprland/tofi.nix` — lanceur tofi (config rendue par le
  [daemon d'accent](#theming)).
- `modules/chromium.nix` — chromium + wrappers PWA (`gemini-pwa`,
  `bandlab-pwa`) partageant `~/.config/chromium-$(hostname)`.
- `modules/kde.nix` — thème minimal KDE/Qt (pour xdg-portal-kde).
- `modules/accent/accent.nix` — installe le [daemon d'accent](#theming) et ses
  templates.
- `modules/shell/` — `fish`, `starship`, `fastfetch`, `micro`, `direnv`, `yazi`.
- `modules/network/` — `git`, `ssh`.
- `modules/code/` — Zed (headful uniquement) + assistants IA (claude, copilot,
  mcp) + runtimes de langages.

## Chromium & PWAs

Les wrappers PWA partagent `~/.config/chromium-$(hostname)`, tous en
`--force-dark-mode` :

- `gemini-pwa` → gemini.google.com (workspace spécial Super+G)
- `bandlab-pwa` → bandlab.com
