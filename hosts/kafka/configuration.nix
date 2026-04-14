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
  networking.hostName = "kafka";

  # Headless server (no GUI)
  head = false;

  # Legacy BIOS / MBR — GRUB installs to the disk MBR (no ESP)
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    efiSupport = false;
    useOSProber = false;
  };

  # Static IP (systemd-networkd; disable NetworkManager for declarative config)
  # FIXME: Adjust interface name and IP address for your network configuration
  networking.networkmanager.enable = true;

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

  # NVIDIA GT 630 (Kepler/GK208) — GPU is broken, using nomodeset (VESA/framebuffer only)
  # Blacklist all GPU drivers since GPU is non-functional
  boot.blacklistedKernelModules = [
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
    "nouveau"
    "amdgpu"
    "radeon"
  ];

  boot.kernelParams = [
    "nomodeset" # Disable kernel mode setting — uses basic VESA framebuffer
  ];

  # HDD mounts - Samsung HD161GJ (149GB) at /mnt/hdd1
  fileSystems."/mnt/hdd1" = {
    device = "/dev/disk/by-uuid/c2237143-9648-451c-a713-23368205effe";
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
}
