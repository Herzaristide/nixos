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
  networking.interfaces.eth0 = {
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

  # Prevent NVIDIA proprietary modules from loading (headless - no display stack)
  boot.blacklistedKernelModules = [
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
  ];

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
