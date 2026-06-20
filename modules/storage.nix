{ ... }:

{
  # Filesystem drivers
  boot.supportedFilesystems = [ "ntfs" ];

  # mdadm software RAID — auto-assemble arrays from superblocks at boot.
  # /dev/md/<name> symlinks created from the array name embedded in the superblock.
  # mdmonitor.service est démarré automatiquement par boot.swraid.enable.
  # MAILADDR root : silence le warning d'eval ("Neither MAILADDR nor PROGRAM
  # has been set") et redirige les alertes mdmon vers le mail système local
  # (perdu sans MTA, ce qui est OK ici — on n'a pas de RAID critique en prod).
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    MAILADDR root
  '';

  # udisks2: hotplug auto-mount for removable media (USB sticks, etc.)
  services.udisks2.enable = true;
  services.fstrim.enable = true;

  # Montages automatiques désactivés temporairement (changement de disques en cours).
  # All known internal HDDs across all hosts. `nofail` lets the host boot
  # even if a given disk is not physically present, so disks remain
  # portable between machines: plug a disk into any host, and it mounts
  # at the same semantic path declared here.
  # fileSystems = {
  #   # Seagate ST1000LM035 — 931G NTFS (labeled "Maxtor", currently in gary)
  #   "/mnt/maxtor" = {
  #     device = "/dev/disk/by-uuid/FE6EC66C6EC61D71";
  #     fsType = "ntfs3";
  #     options = [
  #       "nofail"
  #       "uid=1000"
  #       "gid=1000"
  #       "umask=0022"
  #     ];
  #   };
  #   # Samsung HD161GJ — 149G ext4 (currently in kafka)
  #   "/mnt/samsung" = {
  #     device = "/dev/disk/by-uuid/c2237143-9648-451c-a713-23368205effe";
  #     fsType = "ext4";
  #     options = [ "nofail" ];
  #   };
  #   # 3x Seagate ST2000* assembled as mdadm RAID 5 (sda/sdc/sdd on gary),
  #   # formatted btrfs. ~4 TB usable.
  #   # mdadm array UUID: 679e04b9:3d7f7bdb:26e423a2:bbe98132 — name "gary:raid5".
  #   "/mnt/raid" = {
  #     device = "/dev/disk/by-uuid/513523d5-0b2b-4d07-917c-4a808ccf3c5c";
  #     fsType = "btrfs";
  #     options = [
  #       "nofail"
  #       "compress=zstd:3"
  #       "noatime"
  #       "space_cache=v2"
  #     ];
  #   };
  # };
}
