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
      kubectl
      k9s            # TUI for Kubernetes
      helm
      podman-compose
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

    # Podman
    virtualisation.podman = {
      enable = true;
      dockerCompat = false;  # don't alias docker → podman (Docker is already enabled)
      defaultNetwork.settings.dns_enabled = true;
    };

    # k3s — lightweight Kubernetes cluster
    services.k3s = {
      enable = true;
      role = "server";
      extraFlags = toString [
        "--write-kubeconfig-mode=644"  # readable kubeconfig without sudo
        "--container-runtime-endpoint=unix:///run/containerd/containerd.sock"
      ];
    };

    # Open firewall ports for k3s
    networking.firewall.allowedTCPPorts = [
      6443  # k3s API server
    ];


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


