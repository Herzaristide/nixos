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

  # Option for dark/light color scheme
  options.darkMode = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Use dark color scheme (false = light mode).";
  };

  config = {

    nixpkgs.config.allowUnfree = true;

    # Required by nixd (Nix IDE) when evaluating flake-based options/expressions.
    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    # Automatic garbage collection: delete builds older than 7 days
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };

    # Keep only the last 10 boot entries in systemd-boot
    boot.loader.systemd-boot.configurationLimit = 10;

    # Virtual console (TTY) — French AZERTY for all hosts
    console = {
      enable = true;
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

    # Site blocking (YouTube, Twitch)
    networking.extraHosts = ''
      0.0.0.0 youtube.com www.youtube.com m.youtube.com tv.youtube.com gaming.youtube.com youtu.be youtube-nocookie.com
      0.0.0.0 youtubei.googleapis.com youtube.googleapis.com
      0.0.0.0 ytimg.com www.ytimg.com i.ytimg.com s.ytimg.com
      0.0.0.0 twitch.tv www.twitch.tv m.twitch.tv dashboard.twitch.tv passport.twitch.tv gql.twitch.tv
      0.0.0.0 static.twitchcdn.net vod-secure.twitch.tv vod-metro.twitch.tv usher.ttvnw.net
    '';

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
      gnumake
      gcc

      # Container tools
      podman-compose
      ollama # CLI pour ollama pull/run

      # Development (SonarQube extension)
      jdk21 # Java 21 LTS
      nodejs_22 # Node.js 22 LTS
      terminus_font
      powertop # Power consumption analyzer
      acpi # Battery status CLI tool
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

    # Allow aristide to query disk temperatures without password (read-only, safe)
    security.sudo.extraRules = [
      {
        users = [ "aristide" ];
        commands = [
          {
            command = "${pkgs.smartmontools}/bin/smartctl";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];

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

    # /records directory for voice memos (OllamaChat audio recording tool)
    systemd.tmpfiles.rules = [
      "d /records 0755 aristide users -"
    ];

    # System state version
    system.stateVersion = "25.11";

    # Home Manager
    home-manager = {
      backupFileExtension = "bak";
      extraSpecialArgs = {
        inherit inputs;
        head = config.head;
        darkMode = config.darkMode;
      };
      users.aristide = import ../home/home.nix;
    };
  };
}
