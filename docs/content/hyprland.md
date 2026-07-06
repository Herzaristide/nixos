---
title: Hyprland
group: Bureau
summary: Configuration Hyprland en mode Lua — keybinds, moniteurs, workspaces spéciaux.
links: [home-manager, zola, theming, quickshell]
---

# Hyprland

Le compositeur Wayland, configuré côté [home-manager](#home-manager)
(`modules/hyprland.nix`).

## Mode Lua

- `wayland.windowManager.hyprland.configType = "lua"` — la configuration est
  émise via les helpers `lib.generators`, ce qui autorise `mkLuaInline` pour du
  Lua natif. **Ce n'est pas le format `hypr.conf` classique** (voir
  [Points d'attention](#quirks)).

## Entrées & apparence

- Clavier : AZERTY français (`kb_layout = "fr"`).
- Souris : accélération plate + `force_no_accel = true` (1:1).
- `cursor.no_hardware_cursors = 1` — requis pour NVIDIA + Wayland (voir
  [zola](#zola)).
- `decoration.active_opacity = 0.75` / `inactive_opacity = 0.60`.

## Workspaces spéciaux

- Scratchpad `gemini` : auto-lance `gemini-pwa` via `on_created_empty`
  (Super+G).

## Écran & couleur

- Sur [zola](#zola), `hypr-closed-lid-layout` déplace les workspaces 1-5 vers
  `HDMI-A-1` et désactive `eDP-1` quand le capot est fermé.
- La couleur d'accent est sourcée depuis un fragment généré par le
  [daemon d'accent](#theming).
- La barre et le moniteur principal sont gérés par [Quickshell](#quickshell)
  (voir l'option `primaryMonitor` dans [Options](#options)).
