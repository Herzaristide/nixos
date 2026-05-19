# Custom NixOS installer ISO with the flake embedded.
# Build:  nix build .#iso
# Burn:   sudo cp result/iso/*.iso /dev/sdX   (replace sdX with your USB device)
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
  ];

  # Hostname for the live environment
  networking.hostName = "nixos-installer";

  # Embed the entire flake into the ISO at /etc/nixos so install-nixos.sh
  # can reference it directly. The Nix store path is read-only; the install
  # script copies it to /mnt/persist/etc/nixos before running nixos-install.
  environment.etc."nixos".source = lib.cleanSource ../.;

  # Tools needed by install-nixos.sh.
  # (The base installer ISO already ships cryptsetup, btrfs-progs, parted,
  # mkpasswd, nixos-install-tools and git, but we list them explicitly to be safe.)
  environment.systemPackages = with pkgs; [
    cryptsetup
    btrfs-progs
    parted
    dosfstools
    e2fsprogs
    nixos-install-tools
    git
    mkpasswd
    inputs.disko.packages.${pkgs.stdenv.hostPlatform.system}.disko
    # Editor for emergency tweaks
    micro
    # The installer entry point
    (pkgs.writeShellScriptBin "install-nixos" (builtins.readFile ./install-nixos.sh))
  ];

  # Auto-login to root on TTY1 (override installer default "nixos")
  services.getty.autologinUser = lib.mkForce "root";

  # Welcome message shown after autologin (printed by /etc/profile)
  environment.etc."issue".text = ''

    ╔══════════════════════════════════════════════════════════╗
    ║                NixOS Custom Installer                    ║
    ║                                                          ║
    ║  Run:  install-nixos                                     ║
    ║                                                          ║
    ║  This will:                                              ║
    ║    1. Ask which host to install (gary/zola/kafka)        ║
    ║    2. Partition the selected disk (LUKS + btrfs)         ║
    ║    3. Set user passwords                                 ║
    ║    4. Install NixOS with the full configuration          ║
    ║                                                          ║
    ╚══════════════════════════════════════════════════════════╝

  '';

  # Networking — needed to fetch flake deps (binary caches) during install
  networking.networkmanager.enable = true;
  networking.wireless.enable = lib.mkForce false;

  # ZFS isn't used; explicit setting silences a 26.11 transition warning
  boot.zfs.forceImportRoot = false;

  # Nix settings for the live environment
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "root" ];
  };

  # ISO label
  image.fileName = "nixos-custom-installer.iso";
  isoImage.volumeID = "NIXOS_INSTALL";
}
