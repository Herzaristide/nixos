{ config, pkgs, lib, ... }:

{
  # WSL-specific overrides for headless configuration
  # This module disables incompatible settings from common.nix for WSL

  # Disable bootloader - WSL doesn't use a bootloader
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;

  # Disable NetworkManager - WSL uses Windows networking
  networking.networkmanager.enable = false;
  # Use minimal networking configuration for WSL
  networking.useDHCP = false;
  networking.useNetworkd = false;

  # Filter out hardware-specific packages that don't work in WSL
  # Remove hardware packages from the packages defined in common.nix
  # Use mkOverride to replace the list after common.nix has been evaluated
  environment.systemPackages = lib.mkOverride 50 (
    let
      # Hardware packages to exclude
      hardwarePackages = with pkgs; [
        smartmontools  # SSD/HDD health - requires hardware access
        pciutils       # lspci - limited in WSL
        usbutils       # lsusb - limited in WSL
        lm_sensors     # CPU/GPU temps - doesn't work in WSL
        dmidecode      # BIOS/motherboard info - doesn't work in WSL
      ];
      # Filter function to remove hardware packages
      filterHardware = pkg: !(lib.elem pkg hardwarePackages);
    in
      lib.filter filterHardware config.environment.systemPackages
  );

  # Remove networkmanager from user groups (handled in exupery config)
  # Docker/Podman/Ollama are already configured in common.nix, no need to duplicate
}
