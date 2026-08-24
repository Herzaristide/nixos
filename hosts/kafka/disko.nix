# Disko spécifique à kafka (Dell Precision T3610).
#
# Le firmware du T3610 ne sait pas booter sur NVMe (pas de driver dans l'UEFI) :
# l'ESP/boot vit donc sur une CLÉ USB qui sert de relais de boot, et le NVMe
# ne porte QUE LUKS2 + btrfs. Layout déclaratif complet -> réinstall propre.
#
# Diffère du disko partagé (modules/disko.nix, utilisé par zola/gary) qui place
# l'ESP sur le NVMe. kafka importe ce fichier à la place, via flake.nix.
{
  disko.devices = {
    disk = {
      # --- NVMe (sur adaptateur PCIe) : LUKS2 + btrfs uniquement, PAS d'ESP ---
      nvme = {
        type = "disk";
        device = "/dev/nvme0n1";
        content = {
          type = "gpt";
          partitions = {
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
                  };
                };
              };
            };
          };
        };
      };

      # --- Clé USB relais : porte l'ESP (FAT32, /boot) ---
      #
      # device référencé par by-id : INDISPENSABLE pour ne jamais confondre la
      # clé relais avec une autre clé USB (p. ex. la live d'installation).
      # Clé relais = Generic Flash Disk 3,8 Go (ls -l /dev/disk/by-id/).
      usb = {
        type = "disk";
        device = "/dev/disk/by-id/usb-Generic_Flash_Disk_13D0FD63-0:0";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "100%";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                # Label stable, repris par le bootloader / les montages.
                extraArgs = [
                  "-n"
                  "KAFKABOOT"
                ];
                # nofail : la racine reste montable même clé absente.
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                  "nofail"
                ];
              };
            };
          };
        };
      };
    };
  };
}
