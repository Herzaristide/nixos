{ pkgs, ... }:

{
  # Filesystem drivers
  boot.supportedFilesystems = [ "ntfs" ];
  environment.systemPackages = [ pkgs.nvme-cli ];
  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    MAILADDR root
  '';
  services.udisks2.enable = true;
  services.fstrim.enable = true;

  environment.etc."udisks2/mount_options.conf".text = ''
    [defaults]
    vfat_defaults=uid=$UID,gid=$GID,noexec,nosuid,nodev
    exfat_defaults=uid=$UID,gid=$GID,noexec,nosuid,nodev
    ntfs_defaults=uid=$UID,gid=$GID,noexec,nosuid,nodev
    ext4_defaults=noexec,nosuid,nodev
    btrfs_defaults=noexec,nosuid,nodev
  '';

  fileSystems."/mnt/crucial" = {
    device = "/dev/disk/by-uuid/91bb1965-362e-4f06-b7d3-6881bef81b3f";
    fsType = "btrfs";
    options = [
      "nofail"
      "compress=zstd"
      "noatime"
      "space_cache=v2"
      "discard=async"
      "ssd"
    ];
  };
}
