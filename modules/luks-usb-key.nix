{ ... }:

# Auto-déverrouillage LUKS par clé USB — serveurs seulement (gary, kafka), pour
# qu'ils redémarrent sans quelqu'un devant l'écran. Les portables (bernanos,
# exupery) demandent la passphrase : pas de clé qui voyage avec la machine.
#
# Le keyfile (4096 octets) vit au début d'une partition GPT labellée "LUKSKEY"
# sur une clé USB dédiée. systemd-cryptsetup résout le symlink au boot et lit
# les 4096 premiers octets. Clé absente → fallback automatique sur la passphrase
# après keyFileTimeout secondes. Partlabel choisi (et non vendor/product IDs)
# parce que les clés USB bon marché ont des descripteurs USB instables.
#
# Préparation d'une clé USB neuve :
#   sudo wipefs -a /dev/sdX
#   sudo sgdisk -n 1:0:+1M -t 1:8300 -c 1:"LUKSKEY" /dev/sdX
#   sudo dd if=/dev/urandom of=/dev/sdX1 bs=4096 count=1 conv=fsync
#
# Enrôlement sur une nouvelle machine :
#   sudo cryptsetup luksAddKey /dev/<partition-luks> /dev/sdX1 --new-keyfile-size 4096
#
# Test sans reboot :
#   sudo cryptsetup open --test-passphrase /dev/<partition-luks> _t \
#     --key-file /dev/disk/by-partlabel/LUKSKEY --keyfile-size 4096 && echo OK
{
  boot.initrd.luks.devices.cryptroot = {
    keyFile = "/dev/disk/by-partlabel/LUKSKEY";
    keyFileSize = 4096;
    keyFileOffset = 0;
    keyFileTimeout = 20;
  };
}
