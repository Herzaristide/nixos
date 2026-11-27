# Disposition disko de nabokov : copie de celle de bernanos.
# UEFI + LUKS2 + btrfs sur /dev/sda (SSD SATA), ESP réservé à root.
{
  disko.devices = {
    disk.main = {
      type = "disk";
      # SSD SATA Samsung MZNTY128HDHP 128 Go (pas de NVMe sur cette machine).
      device = "/dev/sda";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "fmask=0077"
                "dmask=0077"
              ];
            };
          };
          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              passwordFile = "/tmp/disko-luks-passphrase";
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "space_cache=v2"
                      "discard=async"
                      "ssd"
                    ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "space_cache=v2"
                      "discard=async"
                      "ssd"
                    ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "space_cache=v2"
                      "discard=async"
                      "ssd"
                    ];
                  };
                  # Home déclaratif (modules/impermanence.nix) : stockage
                  # persistant de ce qui survit au wipe de @home. Sans
                  # mountpoint — c'est le module qui le monte sur /keep/home,
                  # avec le neededForBoot qu'exige impermanence. Son absence
                  # sert aussi de garde-fou au service rollback-home.
                  "@keep" = { };
                };
              };
            };
          };
        };
      };
    };
  };
}
