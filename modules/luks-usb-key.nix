# Déverrouillage LUKS par clé USB (partagé entre gary, zola, kafka).
#
# Le keyfile (4096 octets) vit au début d'une partition GPT labellée "LUKSKEY"
# sur une clé USB dédiée. systemd-cryptsetup résout le symlink
# /dev/disk/by-partlabel/LUKSKEY au boot et lit les 4096 premiers octets.
# Si la clé est absente, fallback automatique sur la passphrase.
#
# Why partlabel and not vendor/product IDs:
#   Les clés USB bon marché ont des descripteurs USB instables (idVendor/
#   idProduct/serial changent entre boots), et un ID générique comme
#   "abcd:1234" matche n'importe quel clone du même chip. Le partlabel est
#   stocké dans la table GPT, donc stable et propre à *cette* clé physique.
#
# Préparation d'une clé USB neuve :
#
#     sudo wipefs -a /dev/sdX
#     sudo sgdisk -n 1:0:+1M -t 1:8300 -c 1:"LUKSKEY" /dev/sdX
#     sudo dd if=/dev/urandom of=/dev/sdX1 bs=4096 count=1 conv=fsync
#
# Enrôlement du keyfile sur une nouvelle machine :
#
#     sudo cryptsetup luksAddKey /dev/<partition-luks> /dev/sdX1 \
#         --new-keyfile-size 4096
#
# Pour tester sans rebooter :
#
#     sudo cryptsetup open --test-passphrase /dev/<partition-luks> _t \
#         --key-file /dev/disk/by-partlabel/LUKSKEY --keyfile-size 4096 \
#         && echo OK
{ ... }:

{
  boot.initrd.luks.devices.cryptroot = {
    keyFile = "/dev/disk/by-partlabel/LUKSKEY";
    keyFileSize = 4096;
    keyFileOffset = 0;
    keyFileTimeout = 20;
  };
}
