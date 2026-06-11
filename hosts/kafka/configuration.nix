{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.home-manager.nixosModules.default
    ../../modules/nixos.nix
    ../../modules/common.nix
    ../../modules/kernel.nix
    ../../modules/network.nix
    ../../modules/power.nix
    ../../modules/storage.nix
    ../../modules/bluetooth.nix
    ../../modules/security.nix
  ];

  # Hostname
  networking.hostName = "kafka";

  # Headless server (no GUI)
  head = false;

  # UEFI boot via systemd-boot
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # CPU: Intel — KVM virtualization + microcode update
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # GPU: NVIDIA NVS 310 (Fermi / GF119) — too old for the current proprietary
  # driver. Use the in-tree nouveau driver: gives a clean KMS console for
  # serial-less local recovery without pulling the legacy_390 package (which
  # doesn't build against recent kernels).
  hardware.graphics.enable = true;
}
