# Modules kernel/initrd + firmware partagés par tous les hôtes physiques
# (zola, gary, kafka). Pas exupery — WSL n'utilise pas d'initrd réel.
{ ... }:

{
  hardware.enableRedistributableFirmware = true;

  boot.initrd.kernelModules = [ "dm-crypt" ];

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
