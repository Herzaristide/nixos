{
  config,
  pkgs,
  inputs,
  lib,
  modulesPath,
  ...
}:

{
  # Hardware autodetection helper (was duplicated in every hardware-configuration.nix)
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # Option for head (GUI) configuration
  options.head = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable head (GUI) configuration";
  };

  # Monitor to use as primary (receives workspaces 1-5, Quickshell bar)
  options.primaryMonitor = lib.mkOption {
    type = lib.types.str;
    default = "HDMI-A-1";
    description = "Hyprland monitor name to use as primary (e.g. eDP-1, HDMI-A-1).";
  };

  # Option for dark/light color scheme
  options.darkMode = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Use dark color scheme (false = light mode).";
  };

  # Persistent /dev/dri path of the DRM card the Wayland compositor should
  # render on. When set, head.nix resolves it to its real card node at login
  # and exports AQ_DRM_DEVICES before exec'ing Hyprland, so aquamarine (and
  # therefore every Wayland client, incl. Chromium) renders on that GPU.
  # Used on gary to keep the whole desktop on the iGPU and leave the discrete
  # RX 7600 XT idle/free for ROCm. null = let aquamarine pick (default).
  # Must be a stable by-path symlink (aquamarine rejects the symlink itself,
  # so head.nix passes it through `readlink -f` to a real cardN node).
  options.renderDevice = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "by-path of the DRM card to pin the Wayland compositor to (AQ_DRM_DEVICES).";
  };

  # GPU discret de l'hôte, utilisé par les applications qui doivent y être
  # épinglées (Blender, cf. home/modules/blender.nix) alors que le compositeur
  # tourne ailleurs (cf. renderDevice). null = pas de GPU discret.
  options.dgpu = {
    vendor = lib.mkOption {
      type = lib.types.nullOr (
        lib.types.enum [
          "nvidia"
          "amd"
        ]
      );
      default = null;
      description = "Vendeur du GPU discret (sélectionne le mécanisme d'offload).";
    };
    driPrime = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Valeur DRI_PRIME du GPU discret (Mesa/AMD), ex. \"pci-0000_03_00_0\".";
    };
  };

  config = {

    # Plateforme cible — identique sur tous les hôtes
    nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

    # Virtual console (TTY) — French AZERTY for all hosts
    # mkDefault on enable so WSL (which disables console) can override without mkForce
    console = {
      enable = lib.mkDefault true;
      earlySetup = true; # Load font in initrd so systemd-vconsole-setup finds it
      font = "ter-v32n";
      packages = [ pkgs.terminus_font ];
      keyMap = "fr";
    };

    # Timezone and locale
    time.timeZone = "Europe/Paris";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "fr_FR.UTF-8";
      LC_IDENTIFICATION = "fr_FR.UTF-8";
      LC_MEASUREMENT = "fr_FR.UTF-8";
      LC_MONETARY = "fr_FR.UTF-8";
      LC_NAME = "fr_FR.UTF-8";
      LC_NUMERIC = "fr_FR.UTF-8";
      LC_PAPER = "fr_FR.UTF-8";
      LC_TELEPHONE = "fr_FR.UTF-8";
      LC_TIME = "fr_FR.UTF-8";
    };

    # Fish as default shell
    programs.fish.enable = true;

    # System-level packages
    environment.systemPackages = with pkgs; [
      # Monitoring & diagnostics
      btop
      iotop
      sysstat # iostat, mpstat, pidstat
      lsof # list open files
      strace # syscall tracer
      smartmontools # SSD/HDD health (smartctl)

      # Hardware info
      pciutils # lspci
      usbutils # lsusb
      lm_sensors # CPU/GPU temps
      dmidecode # BIOS/motherboard info

      # Networking
      curl
      dig # DNS lookup
      nmap # port scanner
      tcpdump # packet capture
      iproute2 # ip, ss
      iperf3 # bandwidth testing
      ethtool # carte réseau / WoL
      wakeonlan # envoi de magic packets

      # Filesystem & disk
      parted
      gptfdisk # sgdisk (GPT partitioning, used for the LUKS USB keyfile)
      tree
      fd # fast find
      ripgrep # fast grep
      file # file type detection
      unzip
      p7zip
      gzip

      # System utilities
      tmux
      jq # JSON processor
      yq-go # YAML processor
      openssl
      envsubst # env variable substitution

      cmatrix
      glances
      mdadm
    ];

    users.mutableUsers = false;

    # aristide password hash is created by nixos-anywhere --extra-files at
    # /etc/passwd-aristide. Root login is disabled (sudo via wheel only).
    users.users.root.hashedPassword = "!";

    users.users.aristide = {
      isNormalUser = true;
      description = "aristide";
      shell = pkgs.fish;
      hashedPasswordFile = "/etc/passwd-aristide";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINi5jJe0xviTwThXWub9t7JdgvJ4OSKhhPfGJSyXbpEg aristide.pichereau@gmail.com"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMKEUyD7riAHBYuRqajNOv+kRWK7b/ORBrVNtmBCipfl aristide.pichereau@gmail.com"
      ];
      extraGroups = [
        "networkmanager"
        "wheel"
        "video"
        "render"
        "audio"
        "storage"
        "greeter"
      ];
    };

    # Allow aristide to query disk temperatures and RAM info without password (read-only, safe)
    security.sudo.extraRules = [
      {
        users = [ "aristide" ];
        commands = [
          {
            command = "${pkgs.smartmontools}/bin/smartctl";
            options = [ "NOPASSWD" ];
          }
          {
            command = "${pkgs.dmidecode}/bin/dmidecode";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

    # Docker rootless : le démon tourne par utilisateur (pas en root), donc
    # appartenir à un groupe "docker" n'équivaudrait plus à un accès root sur
    # l'hôte — d'où l'absence volontaire de ce groupe dans extraGroups ci-dessus.
    # setSocketVariable exporte DOCKER_HOST pour que le CLI `docker` trouve le
    # socket rootless sans configuration manuelle.
    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };

    services.ollama = {
      enable = true;
      host = "127.0.0.1";
    };

    # Home Manager
    home-manager = {
      useUserPackages = true; # Install HM packages to /etc/profiles/per-user/$USER
      useGlobalPkgs = true; # Reuse system nixpkgs instead of home-manager's own instance
      extraSpecialArgs = {
        inherit inputs;
        head = config.head;
        darkMode = config.darkMode;
        primaryMonitor = config.primaryMonitor;
        dgpu = config.dgpu;
        anna = inputs.karenine.packages.${pkgs.stdenv.hostPlatform.system}.anna;
      };
      users.aristide = import ../home/home.nix;
    };
  };
}
