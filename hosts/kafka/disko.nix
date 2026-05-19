# Disko partition layout for kafka (headless server)
# BIOS/GRUB + LUKS2 + btrfs (HDD)
# Override disko.devices.disk.main.device if your disk path differs.
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          # BIOS boot partition (required for GPT + GRUB on BIOS)
          bios_grub = {
            size = "1M";
            type = "EF02";
          };
          boot = {
            size = "512M";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/boot";
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              # Passphrase file consumed only at `disko --mode disko` time by the
              # installer. Path is in tmpfs of the live ISO; harmless if absent
              # on the running system since LUKS is already open by initrd.
              passwordFile = "/tmp/disko-luks-passphrase";
              # No allowDiscards — spinning disk, no TRIM needed
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd:1" "noatime" "space_cache=v2" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd:1" "noatime" "space_cache=v2" ];
                  };
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd:1" "noatime" "space_cache=v2" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
