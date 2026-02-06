# Hardware configuration for WSL (headless/virtualized)
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # WSL-specific hardware configuration
  # WSL runs in a virtualized environment, so minimal hardware config is needed
  boot.initrd.availableKernelModules = [ ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  # WSL typically doesn't need filesystem configuration as it uses the Windows filesystem
  # But you can add it if needed for your specific WSL setup

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

