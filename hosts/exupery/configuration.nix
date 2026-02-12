{ config, pkgs, inputs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    inputs.nixos-wsl.nixosModules.default
    ../../modules/common.nix
  ];

  # Enable WSL integration
  wsl.enable = true;
  wsl.defaultUser = "aristide";

  services.xserver.enable = false;

  # Hostname
  networking.hostName = "exupery";

  # Head configuration
  head = false;

  # WSL-specific overrides (different from common.nix)

  # Disable bootloader - WSL doesn't use a bootloader
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;

  # Disable NetworkManager - WSL uses Windows networking
  networking.networkmanager.enable = false;
  networking.useDHCP = false;
  networking.useNetworkd = false;

  # System packages - remove hardware-specific packages that don't work in WSL
  # Filter out hardware packages from common.nix packages
  environment.systemPackages = lib.filter
    (pkg: !(lib.elem pkg [
      pkgs.smartmontools  # SSD/HDD health - requires hardware access
      pkgs.pciutils       # lspci - limited in WSL
      pkgs.usbutils       # lsusb - limited in WSL
      pkgs.lm_sensors     # CPU/GPU temps - doesn't work in WSL
      pkgs.dmidecode      # BIOS/motherboard info - doesn't work in WSL
    ]))
    config.environment.systemPackages;

  # WSL-specific user group overrides (remove networkmanager, video, render groups)
  users.users.aristide.extraGroups = [ "wheel" "docker" "podman" ];
}
