# Déverrouillage LUKS par clé USB (partagé entre gary, zola, kafka).
#
# Le keyfile (4096 octets) est écrit au début du device USB brut. systemd-cryptsetup
# attend jusqu'à 20s qu'un device avec le bon serial soit énumérée, puis lit les
# 4096 premiers octets. Si la clé est absente, fallback automatique sur la passphrase.
#
# Le nom by-id (basé sur vendor/model) n'est pas stable pour cette clé selon
# l'USB descriptor négocié à chaque boot — on utilise donc une règle udev qui
# crée un symlink stable /dev/luks-key basé sur le numéro de série.
#
# Enrôlement du keyfile sur une nouvelle machine (lire la clé directement sur l'USB) :
#
#     sudo cryptsetup luksAddKey /dev/<partition-luks> /dev/<bloc-usb> --new-keyfile-size 4096
#
# Pour vérifier :
#
#     sudo cryptsetup open --test-passphrase /dev/<partition-luks> _t \
#         --key-file /dev/luks-key --keyfile-size 4096 && echo OK
{ ... }:

let
  # Cette clé USB n'a pas de numéro de série stable — on match sur
  # vendor:product (058f:9380 = Alcor Micro Flash Disk).
  # Attention : n'importe quelle autre clé du même chipset matcherait aussi.
  vendorId = "058f";
  modelId = "6387";
  # Match via attributs sysfs (idVendor/idProduct) plutôt que ENV{ID_USB_*},
  # parce que ces ENV ne sont peuplés que par les règles udev userspace, qui
  # ne sont pas toutes embarquées dans l'initrd minimal de NixOS.
  udevRule = ''
    SUBSYSTEM=="block", ATTRS{idVendor}=="${vendorId}", ATTRS{idProduct}=="${modelId}", SYMLINK+="luks-key"
  '';
in
{
  # Symlink stable côté système (utile pour les tests manuels)
  services.udev.extraRules = udevRule;

  # Symlink stable côté initrd (utilisé au boot par systemd-cryptsetup)
  boot.initrd.services.udev.rules = udevRule;

  boot.initrd.luks.devices.cryptroot = {
    keyFile = "/dev/luks-key";
    keyFileSize = 4096;
    keyFileOffset = 0;
    keyFileTimeout = 20;
  };
}
