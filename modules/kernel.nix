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
    # NIC Ethernet — nécessaires pour SSH dans l'initrd (unlock LUKS à
    # distance). Superset des drivers courants : seul celui qui matche la
    # NIC réelle de l'hôte s'active, les autres restent inertes.
    "e1000e" # Intel Gigabit (laptops + desktops Intel récents)
    "igb" # Intel Gigabit Server
    "igc" # Intel I225/I226 (2.5GbE)
    "r8169" # Realtek RTL8111/8168 (cartes mères grand public)
    "tg3" # Broadcom Tigon3
    "atlantic" # Aquantia 10GbE
  ];

  # Déverrouillage LUKS à distance via SSH dans l'initrd.
  # Workflow : la machine boote → initrd lance sshd sur le port 2222 →
  # `ssh -p 2222 root@<host>` → `systemd-tty-ask-password-agent` pour
  # fournir la passphrase LUKS → le boot reprend.
  #
  # On réutilise la hostkey SSH système (/etc/ssh/ssh_host_ed25519_key)
  # générée automatiquement par services.openssh.enable au premier boot.
  # Tradeoff : cette clé privée est copiée dans l'initramfs sur /boot
  # NON chiffré ; un accès physique au disque permet d'extraire la clé
  # privée et de MITM le serveur. Acceptable pour ce homelab.
  boot.initrd.systemd.enable = true;
  boot.kernelParams = [ "ip=dhcp" ];
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 2222;
      hostKeys = [ "/etc/ssh/ssh_host_ed25519_key" ];
      authorizedKeys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICpZkVir2j2/+z/E6eqLaGrWiR9ukLCE00YCMOx51KyT aristide.pichereau@gmail.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINi5jJe0xviTwThXWub9t7JdgvJ4OSKhhPfGJSyXbpEg aristide.pichereau@gmail.com"
      ];
    };
  };
}
