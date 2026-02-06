{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../../modules/common.nix
    ../../modules/head.nix
  ];

  # Hostname
  networking.hostName = "gary";

  # Head configuration
  head = true;
}
