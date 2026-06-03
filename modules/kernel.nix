# Modules kernel/initrd + firmware partagés par tous les hôtes physiques
# (zola, gary, kafka). Pas exupery — WSL n'utilise pas d'initrd réel.
{ ... }:

{
  # Firmware redistribuable (Wi-Fi/BT Intel & Realtek, microcode CPU,
  # xhci_pci_renesas, GPU AMD/nouveau, etc.). Tire ~500 MB de linux-firmware
  # mais évite des diagnostics pénibles de matériel "muet".
  # Le microcode CPU lui-même est activé par hôte (cf. hardware.cpu.*.updateMicrocode
  # dans hosts/<host>/configuration.nix) puisqu'il dépend du vendor.
  hardware.enableRedistributableFirmware = true;

  # dm-crypt requis dans l'initrd pour ouvrir le LUKS root
  boot.initrd.kernelModules = [ "dm-crypt" ];

  # Modules initrd centralisés pour tous les hôtes.
  # availableKernelModules = "disponibles si udev les demande" (pas "chargés
  # systématiquement") — donc inoffensif d'inclure des modules non utilisés
  # par un hôte donné. Centraliser ici évite que la clé USB de déverrouillage
  # LUKS échoue à monter sur un hôte qui n'a pas explicitement déclaré
  # usb_storage/usbhid/sd_mod dans son hardware-configuration.nix.
  boot.initrd.availableKernelModules = [
    # Stockage
    "nvme"
    "ahci"
    "sd_mod"
    "sr_mod"
    # Contrôleurs USB (xHCI = USB3, eHCI = USB2, oHCI/uHCI = USB1.1)
    "xhci_pci"
    "xhci_pci_renesas"
    "ehci_pci"
    "ehci_hcd"
    "ohci_pci"
    "ohci_hcd"
    "uhci_hcd"
    # Devices USB
    "usb_storage"
    "usbhid"
  ];
}
