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

  # SSH - allow connections without authentication (WSL only, local access)
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitEmptyPasswords = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Allow user to have empty password for passwordless SSH access
  users.users.aristide = {
    hashedPassword = null;  # Allow empty password
    password = null;         # No password set
  };
}
