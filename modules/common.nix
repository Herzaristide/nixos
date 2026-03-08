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

  config = {

    nixpkgs.config.allowUnfree = true;

    # Required by nixd (Nix IDE) when evaluating flake-based options/expressions.
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

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
    environment.interactiveShellInit = ''
      # Enable automatic line wrapping (DECAWM - DEC Auto Wrap Mode)
      printf '\033[?7h'
    '';

    # nix-ld for running unpatched dynamic executables on NixOS
    programs.nix-ld.enable = true;
    programs.nix-ld.libraries = with pkgs; [
      # Add any missing dynamic libraries here if needed
      stdenv.cc.cc
      zlib
      fuse3
      icu
      nss
      openssl
      curl
      expat
    ];

    # System-level packages
    environment.systemPackages = with pkgs; [
      # Monitoring & diagnostics
      upower
      htop
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
      wget
      dig # DNS lookup
      nmap # port scanner
      tcpdump # packet capture
      iproute2 # ip, ss
      iperf3 # bandwidth testing

      # Filesystem & disk
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
      envsubst # env variable substitution
      gnumake
      gcc

      # Container & k8s tools
      kubectl
      helm
      k9s
      podman-compose
      ollama # CLI pour ollama pull/run

      # Development (SonarQube extension Cursor)
      jdk17 # Java 17 LTS
      nodejs_22 # Node.js 22 LTS
    ];

    users.users.aristide = {
      isNormalUser = true;
      description = "aristide";
      shell = pkgs.fish;
      extraGroups = [
        "networkmanager"
        "wheel"
        "docker"
        "video"
        "render"
        "podman"
        "audio"
        "storage"
        "greeter"
        "gamemode"
      ];
    };

    # Docker
    virtualisation.docker.enable = true;

    # Ollama — LLM local (ollama run llama3, etc.)
    services.ollama = {
      enable = true;
      openFirewall = true;
    };

    # Podman
    virtualisation.podman = {
      enable = true;
      dockerCompat = false;
      defaultNetwork.settings.dns_enabled = true;
    };

    # System state version
    system.stateVersion = "25.11";

    # Home Manager
    home-manager = {
      backupFileExtension = "bak";
      extraSpecialArgs = {
        inherit inputs;
        head = config.head;
      };
      users.aristide = import ../home/home.nix;
    };
  };
}
