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

  # Bootloader (systemd-boot for UEFI; GRUB disabled)
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Static IP (systemd-networkd; disable NetworkManager for declarative config)
  # FIXME: Adjust interface name and IP address for your network configuration
  networking.networkmanager.enable = true;
  networking.useDHCP = false;
  networking.interfaces.wlp39s0 = {
    ipv4.addresses = [
      {
        address = "192.168.1.101";
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

  # Prevent all GPU modules from loading (headless - no GPU)
  boot.blacklistedKernelModules = [
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
    "nouveau"
    "radeon" # AMD/ATI legacy GPUs
    "amdgpu" # AMD modern GPUs
  ];

  # HDD mounts (optional - nofail allows boot without these disks)
  # FIXME: Replace UUIDs with your actual disk UUIDs from `lsblk -f` or `blkid`
  # Uncomment and configure the mounts you need:
  #
  # fileSystems."/mnt/hdd1" = {
  #   device = "/dev/disk/by-uuid/YOUR-UUID-HERE";
  #   fsType = "ext4";
  #   options = [ "nofail" ];
  # };
  # fileSystems."/mnt/hdd2" = {
  #   device = "/dev/disk/by-uuid/YOUR-UUID-HERE";
  #   fsType = "ext4";
  #   options = [ "nofail" ];
  # };

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
