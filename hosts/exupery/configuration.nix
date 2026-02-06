{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../../modules/common.nix
  ];

  services.xserver.enable = false;

  # Hostname
  networking.hostName = "exupery";

  # Head configuration
  head = false;
}
