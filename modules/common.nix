{ config, pkgs, inputs, lib, ... }:

{
  # Option for head (GUI) configuration
  options.head = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable head (GUI) configuration";
  };


  config = {

    # Bootloader (systemd-boot for UEFI; GRUB disabled)
    boot.loader.grub.enable = false;
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    nixpkgs.config.allowUnfree = true;
    # Networking
    networking.networkmanager.enable = true;

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

    # Zsh as default shell (required when users.users.aristide.shell = pkgs.zsh)
    programs.zsh.enable = true;

    # System-level packages
    environment.systemPackages = with pkgs; [
      # Monitoring & diagnostics
      htop
      btop
      iotop
      sysstat        # iostat, mpstat, pidstat
      lsof           # list open files
      strace         # syscall tracer
      smartmontools  # SSD/HDD health (smartctl)

      # Hardware info
      pciutils       # lspci
      usbutils       # lsusb
      lm_sensors     # CPU/GPU temps
      dmidecode      # BIOS/motherboard info

      # Networking
      curl
      wget
      dig            # DNS lookup
      nmap           # port scanner
      tcpdump        # packet capture
      iproute2       # ip, ss
      iperf3         # bandwidth testing

      # Filesystem & disk
      tree
      fd             # fast find
      ripgrep        # fast grep
      file           # file type detection
      unzip
      p7zip
      gzip

      # System utilities
      tmux
      jq             # JSON processor
      yq-go          # YAML processor
      envsubst       # env variable substitution
      gnumake
      gcc

      # Container & k8s tools
      podman-compose
      ollama              # CLI pour ollama pull/run

      # Development (SonarQube extension Cursor)
      jdk17               # Java 17 LTS
      nodejs_22           # Node.js 22 LTS
    ];

    # User account
    users.users.aristide = {
      isNormalUser = true;
      description = "aristide";
      extraGroups = [ "networkmanager" "wheel" "docker" "video" "render" "podman" ];
      shell = pkgs.zsh;
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
      dockerCompat = false;  # don't alias docker → podman (Docker is already enabled)
      defaultNetwork.settings.dns_enabled = true;
    };

    # System state version
    system.stateVersion = "25.11";

    # Home Manager
    home-manager = {
      extraSpecialArgs = { 
        inherit inputs; 
        head = config.head;
      };
      users.aristide = import ../home/home.nix;
    };
  };
}


