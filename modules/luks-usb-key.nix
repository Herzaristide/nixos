# Déverrouillage LUKS par clé USB (partagé entre gary, zola, kafka).
#
# Le keyfile (4096 octets) est écrit au début du device USB brut. systemd-cryptsetup
# attend jusqu'à 10s que la clé soit énumérée, puis lit les 4096 premiers octets.
# Si la clé est absente ou expirée, fallback automatique sur la passphrase.
#
# Enrôlement du keyfile sur une nouvelle machine (lire directement la clé sur l'USB) :
#
#     sudo cryptsetup luksAddKey /dev/<partition-luks> \
#         --key-file /dev/disk/by-id/usb-Generic_USB_Flash_Disk_933C4A92-0:0 \
#         --keyfile-size 4096
#
# Pour vérifier :
#
#     sudo cryptsetup open --test-passphrase /dev/<partition-luks> _t \
#         --key-file /dev/disk/by-id/usb-Generic_USB_Flash_Disk_933C4A92-0:0 \
#         --keyfile-size 4096 \
#         && echo OK
{ ... }:

{
  boot.initrd.luks.devices.cryptroot = {
    keyFile = "/dev/disk/by-id/usb-Generic_USB_Flash_Disk_933C4A92-0:0";
    keyFileSize = 4096;
    keyFileOffset = 0;
    keyFileTimeout = 10;
  };
}
