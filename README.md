# nixos

Configuration NixOS basée sur des flakes, gérant quatre machines via un dépôt unique. Home-manager est intégré comme module NixOS : `nixos-rebuild` met donc à jour le système **et** l'environnement utilisateur en une seule passe.

## Machines gérées

| Host      | Rôle                  | GPU                              | Particularités                                  |
| --------- | --------------------- | --------------------------------- | ------------------------------------------------ |
| `zola`    | Laptop                | Intel + NVIDIA (Prime *offload*)  | Interface graphique complète (Hyprland)           |
| `gary`    | Desktop                | AMD Ryzen 5 7600X + Radeon 7600 XT (ROCm/HIP) | Interface graphique complète (Hyprland)           |
| `kafka`   | Serveur headless       | Intel + NVIDIA NVS 310 (nouveau)  | UEFI + systemd-boot, sans interface graphique     |
| `exupery` | WSL2                   | —                                  | Environnement de développement headless           |

## Utilisation

```bash
# Reconstruire la machine courante
sudo nixos-rebuild switch --flake .#$(hostname)

# Reconstruire une machine spécifique
sudo nixos-rebuild switch --flake .#zola

# Mettre à jour les inputs du flake
nix flake update

# Vérifier l'évaluation sans build (rapide, détecte les erreurs de syntaxe/logique)
nix flake check --no-build

# Formater les fichiers Nix
nixfmt **/*.nix
```

## Structure du dépôt

```
flake.nix                 # Inputs (nixpkgs, home-manager, nixos-wsl, musnix, quickshell,
                           # karenine, disko) et définition des nixosConfigurations
hosts/<hostname>/          # configuration.nix (spécifique au host) + hardware-configuration.nix
                           # (générée par nixos-generate-config, ne pas éditer à la main)
modules/                   # Modules système partagés (réseau, audio, stockage, disko, sécurité...)
home/                      # Configuration home-manager
  home.nix                #   point d'entrée, modules communs (fish, git, code...)
  head.nix                #   couche GUI utilisateur (dconf, curseur, apps par défaut...)
  modules/                #   Hyprland, Quickshell, Alacritty, Chromium (PWA), Zed, IA...
quickshell/                # Shell Wayland (barre, panneau latéral, chat Ollama, notes...)
accent-daemon/             # Démon de theming (Rust/Python), packagé comme `paletted`
pkgs/                      # Paquets custom supplémentaires
secrets/                   # Secrets chiffrés
```

## L'option `head`

`head` (booléen, `modules/common.nix`) détermine si un host reçoit la couche graphique complète :

- `head = true` (gary, zola) → `modules/head.nix` + modules home-manager graphiques (Hyprland, Quickshell, KDE/Qt theming, Chromium, Alacritty...)
- `head = false` (exupery, kafka) → uniquement les modules CLI/serveur

`primaryMonitor` définit le moniteur Hyprland recevant les workspaces 1-5 et la barre Quickshell. `darkMode` pilote le thème (dconf/GTK/Qt + démon d'accent).

## Theming (démon d'accent)

Un démon custom (`paletted`) génère la configuration de couleurs pour les applications qui la supportent (Hyprland, Alacritty...) à partir de templates dans `~/.config/accent/templates/`. Pour changer la couleur d'accent à chaud :

```bash
palette set "#5277c3"
```

## Paquets custom

- `paletted` (`packages.x86_64-linux.paletted`) — le démon d'accent (`accent-daemon`)
- `pkgs/` contient d'autres dérivations custom (ex. `salamander-grand-piano`)

## Documentation détaillée

Voir [`CLAUDE.md`](./CLAUDE.md) pour une description exhaustive de l'architecture, des particularités de chaque host, de la configuration Hyprland/audio, et des conventions du dépôt.
