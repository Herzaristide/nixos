{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../../modules/nixos.nix
    ../../modules/common.nix
    ../../modules/network.nix
    ../../modules/luks-usb-key.nix
    ../../modules/power.nix
    ../../modules/storage.nix
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

  # Firmware for hardware (network, etc.)
  hardware.enableRedistributableFirmware = true;

  # CPU: Intel — KVM module for virtualization
  boot.kernelModules = [ "kvm-intel" ];

  # USB host controllers in initrd : on charge tous les variants pour que la
  # clé USB de déverrouillage LUKS soit détectée sur n'importe quel port.
  # - ehci/ohci/uhci : USB 2.x et 1.1 (ports façade Intel natifs)
  # - xhci_pci_renesas : contrôleur USB 3.0 Renesas (ports arrière, firmware
  #   propriétaire requis — fourni par enableRedistributableFirmware)
  boot.initrd.availableKernelModules = [
    "ehci_pci"
    "ehci_hcd"
    "ohci_pci"
    "ohci_hcd"
    "uhci_hcd"
    "xhci_pci_renesas"
  ];

  # GPU: NVIDIA NVS 310 (Fermi / GF119) — too old for the current proprietary
  # driver. Use the in-tree nouveau driver: gives a clean KMS console for
  # serial-less local recovery without pulling the legacy_390 package (which
  # doesn't build against recent kernels).
  hardware.graphics.enable = true;
}
