# ISO installateur — image live bootable qui embarque ce flake pour installer
# n'importe quel hôte sur une machine vierge.
#
# Construction : nix build .#iso   (ou .#nixosConfigurations.iso.config.system.build.isoImage)
# Le résultat est sous result/iso/*.iso.
#
# Usage sur la cible (une fois booté sur l'ISO) :
#   sudo nixos-install-here <hostname>
# qui lance disko (partitionnement + LUKS + btrfs) puis nixos-install à partir
# du flake embarqué.
{
  pkgs,
  modulesPath,
  inputs,
  ...
}:
{
  imports = [
    # Base installateur minimale (console, outils réseau, nix).
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Flakes indispensables pour installer depuis ce dépôt.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Le firmware récent boote plus vite avec un kernel à jour ; on garde le
  # défaut de l'installateur mais on active la compression zstd de l'ISO
  # (plus rapide à générer, image plus légère).
  isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  # L'installateur active le support ZFS (all-hardware), ce qui déclenche le
  # warning sur la valeur par défaut de forceImportRoot. La racine du live n'est
  # pas ZFS ; on adopte explicitement la valeur recommandée pour taire le warning.
  boot.zfs.forceImportRoot = false;

  networking.hostName = "nixos-installer";
  # Réseau filaire par défaut (NetworkManager pour le Wi-Fi si besoin).
  networking.networkmanager.enable = true;
  networking.wireless.enable = pkgs.lib.mkForce false;

  # SSH pour installation à distance (nixos-anywhere ou attache manuelle).
  services.openssh = {
    enable = true;
    settings.PermitRootLogin = "yes";
  };

  # L'utilisateur nixos de l'installateur : mot de passe vide + accès sudo,
  # pratique en live. Ajoutez vos clés publiques ici pour l'accès SSH.
  users.users.root.initialHashedPassword = pkgs.lib.mkForce "";
  users.users.nixos.openssh.authorizedKeys.keys = [
    # "ssh-ed25519 AAAA... vous@machine"
  ];

  # Outils présents dans le live pour l'installation.
  environment.systemPackages = with pkgs; [
    git
    inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.default
    parted
    gptfdisk
    cryptsetup
    (writeShellScriptBin "nixos-install-here" ''
      set -euo pipefail
      if [ "$#" -lt 1 ]; then
        echo "usage: nixos-install-here <hostname> [chemin-flake]" >&2
        echo "hôtes disponibles : zola gary kafka exupery" >&2
        exit 1
      fi
      host="$1"
      flake="''${2:-/etc/nixos}"

      echo ">> Partitionnement via disko pour l'hôte $host"
      echo ">> Le flake sera lu depuis : $flake"
      echo ">> ATTENTION : ceci efface le disque cible."
      read -rp "Continuer ? [y/N] " ans
      [ "$ans" = "y" ] || { echo "Annulé."; exit 1; }

      # La passphrase LUKS est lue depuis /tmp/disko-luks-passphrase (voir CLAUDE.md).
      if [ ! -f /tmp/disko-luks-passphrase ]; then
        echo ">> Aucune passphrase LUKS dans /tmp/disko-luks-passphrase."
        read -rsp "Entrez la passphrase LUKS : " luks; echo
        printf '%s' "$luks" > /tmp/disko-luks-passphrase
      fi

      sudo ${disko}/bin/disko \
        --mode disko \
        --flake "$flake#$host"

      echo ">> Installation de NixOS ($host)"
      sudo nixos-install --flake "$flake#$host" --no-root-passwd

      echo ">> Terminé. Rebootez sur le nouveau système."
    '')
  ];

  # Embarque une copie de ce dépôt dans l'ISO, montée en lecture seule sur
  # /etc/nixos, pour installer même sans réseau ni accès au dépôt distant.
  environment.etc."nixos".source = inputs.self;

  # Message d'accueil au login.
  services.getty.helpLine = pkgs.lib.mkForce ''

    Bienvenue sur l'installateur NixOS (flake Herzaristide/nixos).
    Le flake est embarqué sous /etc/nixos.

    Pour installer un hôte :   sudo nixos-install-here <hostname>
    Hôtes : zola  gary  kafka  exupery
  '';

  system.stateVersion = "25.11";
}
