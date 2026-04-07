{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../../modules/common.nix
  ];

  # Hostname
  networking.hostName = "gary";

  # Pas le module « head » (Hyprland/DMS) : GUI minimale X11 ci-dessous
  head = false;

  # Bootloader (systemd-boot for UEFI; GRUB disabled)
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Static IP (systemd-networkd; disable NetworkManager for declarative config)
  networking.networkmanager.enable = true;
  networking.useDHCP = false;
  networking.interfaces.wlp39s0 = {
    ipv4.addresses = [
      {
        address = "192.168.1.100";
        prefixLength = 24;
      }
    ];
  };
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [
    "192.168.1.1"
    "8.8.8.8"
  ];

  # SSH - allow password authentication
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Firmware for hardware (network, etc.)
  hardware.enableRedistributableFirmware = true;

  # Use radeon driver in minimal mode (HD 7870 - Southern Islands)
  services.xserver.videoDrivers = [ "radeon" ];

  # Blacklist only non-AMD drivers and amdgpu (use radeon only)
  boot.blacklistedKernelModules = [
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
    "nouveau"
    "amdgpu" # Use radeon instead for better compatibility with HD 7870
  ];

  # Radeon minimal mode - disable ALL advanced features for maximum stability
  boot.kernelParams = [
    "radeon.dpm=0" # Disable dynamic power management (no clock/voltage changes)
    "radeon.audio=0" # Disable HDMI/DP audio (reduces complexity)
    "radeon.aspm=0" # Disable PCIe power management (more stable)
    "radeon.msi=0" # Disable MSI interrupts (legacy mode, more compatible)
    "radeon.uvd=0" # Disable UVD video decoder (CPU does video decoding)
    "radeon.vce=0" # Disable VCE video encoder
    "radeon.hw_i2c=0" # Disable hardware I2C (monitor detection uses software)
    "radeon.runpm=0" # Disable runtime power management
    "radeon.benchmark=0" # Disable boot benchmarks
    "radeon.pcie_gen2=0" # Force PCIe Gen 1 speed (maximum compatibility)
    "radeon.no_wb=1" # Disable write-back cache
    "radeon.agpmode=-1" # Disable AGP mode (PCIe only)
    "radeon.lockup_timeout=0" # Disable GPU lockup detection
  ];

  # HDD mounts (optional - nofail allows boot without these disks)
  fileSystems."/mnt/hdd1" = {
    device = "/dev/disk/by-uuid/516f5bb5-72b9-47da-b6bb-7b193ac1cd86";
    fsType = "ext4";
    options = [ "nofail" ];
  };
  fileSystems."/mnt/hdd2" = {
    device = "/dev/disk/by-uuid/c25498c3-b03c-43cc-8650-f8183873ceec";
    fsType = "ext4";
    options = [ "nofail" ];
  };
  fileSystems."/mnt/hdd3" = {
    device = "/dev/disk/by-uuid/85a42e9c-ace0-4ecc-a04a-e2e722345d5c";
    fsType = "ext4";
    options = [ "nofail" ];
  };
  fileSystems."/mnt/hdd4" = {
    device = "/dev/disk/by-uuid/8f0502de-aeec-497c-a92a-76ce47fd26de";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  # SSD maintenance — periodic TRIM
  services.fstrim.enable = true;

  # Nix experimental features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # K3s - lightweight Kubernetes cluster (single-node server)
  services.k3s = {
    enable = true;
    role = "server";
  };

  # Firewall disabled for development server (allows access to all ports from other machines)
  # WARNING: Only suitable for trusted local networks. Enable firewall and specify ports for production.
  networking.firewall.enable = false;

  # Auto-login on tty1 for display monitoring
  services.getty.autologinUser = "aristide";

  # Auto-start btop on tty1 login
  programs.fish.loginShellInit = ''
    if test (tty) = "/dev/tty1"
      cmatrix
    end
  '';
}
