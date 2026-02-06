{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../../modules/common.nix
    ../../modules/nvidia.nix
    ../../modules/head.nix
  ];

  # Hostname
  networking.hostName = "zola";

  # Head configuration
  head = true;
}
