# Hardware configuration for laptop
# This file should be generated using: nixos-generate-config --dir /etc/nixos/hosts/laptop
# Or manually configured based on your laptop's hardware
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # Add your laptop's hardware configuration here
  # This is a template - replace with actual hardware scan results
  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # File systems - update with your laptop's UUIDs
  # fileSystems."/" = { ... };
  # fileSystems."/boot" = { ... };
  # swapDevices = [ ... ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

