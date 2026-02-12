{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    inputs.nixos-wsl.nixosModules.default
    ../../modules/common.nix
    ../../modules/wsl.nix
  ];

  # Enable WSL integration
  wsl.enable = true;
  wsl.defaultUser = "aristide";

  services.xserver.enable = false;

  # Hostname
  networking.hostName = "exupery";

  # Head configuration
  head = false;

  # WSL-specific user group overrides (remove networkmanager group)
  users.users.aristide.extraGroups = [ "wheel" "docker" "podman" ];
}
