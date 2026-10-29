---
title: exupery (2-en-1)
group: Hôtes
summary: Dell Latitude 7200 2-en-1, Intel seul, profil graphique complet + tablette.
links: [hosts, bernanos, hyprland, options]
---

# exupery — Dell Latitude 7200 2-en-1

Tablette à clavier détachable, profil graphique complet (`head = true`) comme
[bernanos](#bernanos), avec en plus la rotation, le clavier virtuel et l'émetteur IR déclarés dans `hosts/exupery/configuration.nix`.

## Matériel

- Intel Core i5-8365U (Whiskey Lake, 4c/8t), 16 Go, Intel UHD 620 seul —
  pas de NVIDIA, donc aucune des variables Prime/NVIDIA de bernanos.
- Écran tactile 12,3" 1920×1280 (`eDP-1`, écran principal).
- Même disque que bernanos : GPT + ESP + LUKS2 + btrfs sur `/dev/nvme0n1`
  (`hosts/exupery/disko.nix`), impermanence de `/home`.

## Énergie

- `auto-cpufreq` (plafond 1,6 GHz sur batterie, turbo 4,1 GHz sur secteur),
  `thermald`, `powertop`.
- `fwupd` pour les mises à jour BIOS Dell (`fwupdmgr update`).

## Tablette (`home/modules/tablet.nix`)

- **Rotation automatique** : `iio-sensor-proxy` (`hardware.sensor.iio`) lit
  l'accéléromètre ; le service utilisateur `hypr-auto-rotate` tourne `eDP-1` et
  l'écran tactile via `hyprctl eval`. La rotation est aussi écrite dans
  `$XDG_RUNTIME_DIR/hypr-rotation` et réappliquée à chaque `hyprctl reload`.
- **Clavier virtuel** : `wvkbd`, affiché quand aucun clavier USB n'est branché
  (le clavier détachable en est un), masqué sinon.

## Reconnaissance faciale

- `linux-enable-ir-emitter` + `howdy` en `sufficient`, **uniquement** pour
  l'écran de verrouillage Quickshell et polkit. greetd/login (qui
  déverrouillent GNOME Keyring) et sudo restent au mot de passe.
- Mise en place, une fois : `sudo linux-enable-ir-emitter configure`, puis
  `sudo howdy add`.
