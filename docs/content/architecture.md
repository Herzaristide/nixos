---
title: Architecture générale
group: Général
summary: Organisation du dépôt — flake, modules système, home-manager, hôtes et paquets custom.
links: [flake, system-modules, home-manager, filesystem, packages]
---

# Architecture générale

Le dépôt est structuré autour d'un **flake** qui expose les quatre systèmes et
délègue la configuration à des modules réutilisables.

## Organisation du dépôt

```
.
├── flake.nix              # inputs + nixosConfigurations (voir Le flake)
├── modules/               # modules SYSTÈME partagés (voir Modules système)
├── home/                  # configuration home-manager (voir Home-manager)
├── hosts/<hostname>/      # spécificités par machine (voir Les hôtes)
│   ├── configuration.nix
│   └── hardware-configuration.nix   # généré, ne pas éditer à la main
├── accent-daemon/         # daemon de thème en Rust/Python (voir Theming)
├── quickshell/            # shell Wayland en QML (voir Quickshell)
├── pkgs/                  # paquets custom (voir Paquets custom)
└── secrets/               # secrets (git-ignorés)
```

## Les grandes couches

1. **Le [flake](#flake)** déclare les inputs (nixpkgs, home-manager, disko…) et
   construit un `nixosSystem` par hôte, en injectant `modules/disko.nix` et la
   `configuration.nix` de l'hôte.
2. **Les [modules système](#system-modules)** (`/modules/`) portent tout ce qui
   relève du système : réseau, audio, stockage, couche graphique, réglages Nix.
3. **[Home-manager](#home-manager)** (`/home/`) porte l'environnement
   utilisateur : shell, éditeurs, [Hyprland](#hyprland), [Quickshell](#quickshell),
   [thème](#theming).
4. **Les [hôtes](#hosts)** ne contiennent que le strict spécifique (GPU,
   bootloader, moniteur principal) et activent/désactivent les couches via
   l'option [`head`](#options).

## Le principe directeur

Le comportement d'un hôte est piloté par quelques **options** déclarées dans
`modules/common.nix` (`head`, `primaryMonitor`, `darkMode`) — décrites dans
[Options transversales](#options). Changer un hôte revient le plus souvent à
ajuster ces options plutôt qu'à dupliquer de la configuration.
