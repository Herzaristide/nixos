# Home déclaratif : /home repart vide à chaque boot, seuls les chemins listés
# ci-dessous survivent. Migration initiale : scripts/impermanence-migrate.sh
{ inputs, ... }:

let
  cryptDevice = "/dev/mapper/cryptroot";
  retentionDays = 30;

  btrfsOptions = [
    "compress=zstd"
    "noatime"
    "space_cache=v2"
    "discard=async"
    "ssd"
  ];
in
{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # @keep est l'ancien @home renommé : son `aristide/` tombe donc pile sur
  # /keep/home/aristide, où impermanence attend les données de l'utilisateur.
  # C'est ce qui permet de migrer sans déplacer un fichier.
  fileSystems."/keep/home" = {
    device = cryptDevice;
    fsType = "btrfs";
    options = btrfsOptions ++ [ "subvol=@keep" ];
    neededForBoot = true;
  };

  # Exigé par impermanence : /home devient sysroot-home.mount dans l'initrd,
  # d'où le `before` du rollback ci-dessous.
  fileSystems."/home".neededForBoot = true;

  boot.initrd.systemd.services.rollback-home = {
    description = "Rollback @home vers un snapshot vierge";
    wantedBy = [ "initrd.target" ];
    after = [ "systemd-cryptsetup@cryptroot.service" ];
    before = [
      "sysroot-home.mount"
      "sysroot-keep-home.mount"
    ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /btrfs_tmp
      mount -t btrfs -o subvolid=5 ${cryptDevice} /btrfs_tmp

      # Archivé, pas supprimé : un oubli dans la liste se répare pendant 30 jours.
      if [ -e /btrfs_tmp/@home ]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/@home)" "+%Y-%m-%d_%H:%M:%S")
        mv /btrfs_tmp/@home "/btrfs_tmp/old_roots/$timestamp"
      fi

      # Les subvolumes imbriqués partent avant leur parent.
      delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
          delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
      }

      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +${toString retentionDays} 2>/dev/null); do
        delete_subvolume_recursively "$i"
      done

      btrfs subvolume snapshot /btrfs_tmp/@home-blank /btrfs_tmp/@home

      umount /btrfs_tmp
    '';
  };

  # Tout ce qui n'est PAS ici disparaît au prochain boot.
  environment.persistence."/keep" = {
    hideMounts = true;
    users.aristide = {
      files = [
        ".claude.json"
        ".npmrc"
        # Fichier isolé : le dossier parent contient generated_completions/,
        # régénéré par home-manager à chaque activation.
        ".local/share/fish/fish_history"
        ".local/state/tofi-drun-history"
      ];

      directories = [
        # Secrets
        {
          directory = ".ssh";
          mode = "0700";
        }
        {
          directory = ".local/share/keyrings";
          mode = "0700";
        }
        {
          directory = ".aws";
          mode = "0700";
        }
        {
          directory = ".config/rclone";
          mode = "0700";
        }
        ".pki"

        # État applicatif
        ".claude"
        ".config/accent"
        ".config/chromium"
        ".config/OpenRGB" # profils de périphériques (OpenRGB.json, sizes.ors)
        ".android" # adbkey (autorisation des appareils) + debug.keystore
        ".ollama"
        ".local/share/direnv" # allow-list ; sans elle, tout devDir redemande `direnv allow`
        ".local/state/wireplumber" # volumes et routage audio par périphérique

        # Docker rootless : le data-root est dans le home, pas /var/lib/docker.
        ".local/share/docker"
        ".docker"

        # Données
        "ghub"
        "gpoc"
        "glab"
        "gdrive"
        "musique"
        "Downloads"
      ];
    };
  };
}
