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

  # Headless server (no GUI)
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

  # Prevent all GPU modules from loading (headless - no display stack, GPU disabled for testing)
  boot.blacklistedKernelModules = [
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
    "nouveau"
    "radeon"     # AMD/ATI legacy GPUs
    "amdgpu"     # AMD modern GPUs
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
  # fileSystems."/mnt/hdd3" = {
  #  device = "/dev/disk/by-uuid/85a42e9c-ace0-4ecc-a04a-e2e722345d5c";
  #  fsType = "ext4";
  # };
  # fileSystems."/mnt/hdd4" = {
  #  device = "/dev/disk/by-uuid/0d58df3a-f3b2-4916-bbad-d7cd0f003720";
  #  fsType = "ext4";
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

  # Allow K3s API (6443) for remote kubectl (k3s has no openFirewall option)
  networking.firewall.allowedTCPPorts = [ 6443 ];
}
