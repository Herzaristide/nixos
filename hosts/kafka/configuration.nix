{
  config,
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
    ../../modules/print.nix
  ];

  # Hostname
  networking.hostName = "kafka";

  # Headless server (no GUI)
  head = false;

  # UEFI boot via systemd-boot.
  #
  # Le firmware du Dell Precision T3610 ne dispose pas du driver NVMe : il ne
  # peut pas lire le SSD (NVMe sur adaptateur PCIe) pour y trouver le
  # bootloader. L'ESP/boot vit donc sur une clé USB (label FAT "KAFKABOOT")
  # qui sert de relais : le firmware boote la clé, le kernel chargé contient
  # le driver NVMe, ouvre le LUKS du NVMe et monte la racine btrfs.
  #
  # Le montage /boot (la clé) est déclaré par le disko dédié de kafka
  # (hosts/kafka/disko.nix), en nofail. La clé DOIT être branchée lors d'un
  # `nixos-rebuild`, sinon systemd-boot ne peut pas écrire ses entrées.
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  # Device de boot amovible : pas d'écriture NVRAM. On s'appuie sur le chemin
  # de secours EFI/BOOT/BOOTX64.EFI, que le firmware boote comme média USB.
  boot.loader.efi.canTouchEfiVariables = false;

  # NB : l'auto-déverrouillage LUKS par clé USB (partition GPT "LUKSKEY",
  # fallback passphrase) est fourni par modules/security.nix.

  # CPU: Intel — KVM virtualization + microcode update
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # GPU: NVIDIA NVS 310 (Fermi / GF119) — too old for the current proprietary
  # driver. Use the in-tree nouveau driver: gives a clean KMS console for
  # serial-less local recovery without pulling the legacy_390 package (which
  # doesn't build against recent kernels).
  hardware.graphics.enable = true;
}
