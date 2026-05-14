{ ... }:

{
  # Filesystem drivers
  boot.supportedFilesystems = [ "ntfs" ];

  # udisks2: hotplug auto-mount for removable media (USB sticks, etc.)
  services.udisks2.enable = true;
  services.fstrim.enable = true;

  # All known internal HDDs across all hosts. `nofail` lets the host boot
  # even if a given disk is not physically present, so disks remain
  # portable between machines: plug a disk into any host, and it mounts
  # at the same semantic path declared here.
  fileSystems = {
    # Seagate ST1000LM035 — 931G NTFS (labeled "Maxtor", currently in gary)
    "/mnt/maxtor" = {
      device = "/dev/disk/by-uuid/FE6EC66C6EC61D71";
      fsType = "ntfs3";
      options = [
        "nofail"
        "uid=1000"
        "gid=1000"
        "umask=0022"
      ];
    };
    # Samsung HD161GJ — 149G ext4 (currently in kafka)
    "/mnt/samsung" = {
      device = "/dev/disk/by-uuid/c2237143-9648-451c-a713-23368205effe";
      fsType = "ext4";
      options = [ "nofail" ];
    };
    # Seagate ST2000DM001 — 2T ext4
    "/mnt/seagate-dm001" = {
      device = "/dev/disk/by-uuid/516f5bb5-72b9-47da-b6bb-7b193ac1cd86";
      fsType = "ext4";
      options = [ "nofail" ];
    };
    # Seagate ST2000DM008 — 2T ext4
    "/mnt/seagate-dm008" = {
      device = "/dev/disk/by-uuid/c25498c3-b03c-43cc-8650-f8183873ceec";
      fsType = "ext4";
      options = [ "nofail" ];
    };
    # Seagate ST2000DX001 — 2T SSHD ext4 (hybrid SSD/HDD)
    "/mnt/seagate-sshd" = {
      device = "/dev/disk/by-uuid/8f0502de-aeec-497c-a92a-76ce47fd26de";
      fsType = "ext4";
      options = [ "nofail" ];
    };
  };
}
