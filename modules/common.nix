{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
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

  config = {

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

    # Enable automatic line wrapping in terminals
    # environment.interactiveShellInit = ''
    #   # Enable automatic line wrapping (DECAWM - DEC Auto Wrap Mode)
    #   printf '\033[?7h'
    # '';

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

      # Filesystem & disk
      parted
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

    # Password files are created by deploy.sh (nixos-anywhere --extra-files).
    # They must exist on the target at these paths, containing the sha-512 hash.

    users.users.root = {
      hashedPasswordFile = "/etc/passwd-root";
    };

    users.users.aristide = {
      isNormalUser = true;
      description = "aristide";
      shell = pkgs.fish;
      hashedPasswordFile = "/etc/passwd-aristide";
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "video"
        "render"
        "audio"
        "storage"
        "greeter"
        "gamemode"
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

    # Docker
    virtualisation.docker.enable = true;

    services.ollama = {
      enable = true;
      host = "127.0.0.1";
    };

    # /records directory for voice memos (OllamaChat audio recording tool)
    systemd.tmpfiles.rules = [
      "d /records 0755 aristide users -"
    ];

    # Home Manager
    home-manager = {
      useUserPackages = true; # Install HM packages to /etc/profiles/per-user/$USER
      useGlobalPkgs = true; # Reuse system nixpkgs instead of home-manager's own instance
      extraSpecialArgs = {
        inherit inputs;
        head = config.head;
        darkMode = config.darkMode;
        primaryMonitor = config.primaryMonitor;
        accentDaemon = pkgs.callPackage ../accent-daemon/default.nix { };
      };
      users.aristide = import ../home/home.nix;
    };
  };
}
