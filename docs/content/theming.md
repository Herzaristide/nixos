---
title: Theming — daemon d'accent
group: Bureau
summary: Le daemon Rust/Python « paletted » qui propage une couleur d'accent unique à toutes les apps.
links: [home-manager, hyprland, packages, options]
---

# Theming — le daemon d'accent

Un daemon maison (`/accent-daemon/`, en Rust/Python) propage une **couleur
d'accent unique** à l'ensemble du bureau. Il est packagé comme `accent-daemon`
et exposé aussi sous `packages.x86_64-linux.paletted` (voir [Paquets](#packages)).

## Deux binaires

- `paletted` — le moteur de rendu de templates.
- `palette` — le CLI pour changer la couleur active.

## Fonctionnement

- Les templates sont installés sous `~/.config/accent/templates/`, les fragments
  rendus sous `~/.config/accent/fragments/`.
- Les apps qui supportent les *includes* de couleur ([Hyprland](#hyprland),
  Alacritty…) sourcent directement le fragment depuis leur config Nix déclarative.
- `kdeglobals.tmpl` est rendu comme fichier complet (KDE/Qt n'a pas de directive
  d'include).
- Les outils shell (starship/micro/fastfetch) sont en ANSI statique et **ne sont
  pas** templatés.

## Changer la couleur à chaud

```bash
palette set "#5277c3"
```

Les valeurs par défaut au démarrage dérivent de l'option [`darkMode`](#options).
Le daemon est installé par `home/modules/accent/accent.nix` (voir
[Home-manager](#home-manager)).
