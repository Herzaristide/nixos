{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  rootDevice = config.fileSystems."/".device;
  wipeRoot = pkgs.writeShellApplication {
    name = "wipe-root";
    runtimeInputs = [
      pkgs.btrfs-progs
      pkgs.util-linux
    ];
    text = ''
      mkdir -p /mnt
      mount -t btrfs -o subvol=/ ${rootDevice} /mnt
      trap 'umount /mnt 2>/dev/null || true' EXIT

      echo "Impermanence: wiping @ subvolume..."

      # Delete nested subvolumes deepest-first (btrfs refuses to delete a
      # subvolume that still has children).
      btrfs subvolume list -o /mnt/@ \
        | awk '{print $NF}' \
        | sort -r \
        | while IFS= read -r sub; do
            btrfs subvolume delete "/mnt/$sub"
          done

      btrfs subvolume delete /mnt/@
      btrfs subvolume create /mnt/@

      echo "Impermanence: fresh @ ready."
    '';
  };
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  boot.initrd.supportedFilesystems = [ "btrfs" ];

  boot.initrd.systemd.storePaths = [ "${wipeRoot}/bin/wipe-root" ];
  boot.initrd.systemd.services.wipe-root = {
    description = "Wipe root btrfs subvolume for impermanence";
    wantedBy = [ "initrd.target" ];
    after = [ "initrd-root-device.target" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${wipeRoot}/bin/wipe-root";
    };
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      {
        directory = "/etc/nixos";
        user = "aristide";
        group = "users";
        mode = "0755";
      }
      "/etc/ssh"
      "/etc/NetworkManager/system-connections"
      "/var/log" # inclut /var/log/journal — logs systemd persistés
      "/var/lib/nixos"
      "/var/lib/NetworkManager"
      "/var/lib/docker"
      {
        directory = "/var/lib/private";
        mode = "0700";
      }
      "/var/lib/colord"
      "/var/lib/AccountsService"
      "/var/lib/systemd/backlight" # luminosité écran restaurée au boot
      "/var/lib/systemd/timers" # état des timers persistants
      "/var/lib/upower" # historique batterie
      "/var/lib/fwupd" # cache firmware updates
      "/records"
      {
        directory = "/var/lib/bluetooth";
        user = "root";
        group = "root";
        mode = "0700";
      }
    ];
    files = [
      "/etc/machine-id"
      "/etc/passwd-root"
      "/etc/passwd-aristide"
    ];

    users.aristide = {
      directories = [
        ".ssh"
        ".local/share/fish" # historique fish
        ".local/state/wireplumber" # volumes par app,
      ];
      files = [ ];
    };
  };
}
