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
    ../../modules/nixos.nix
    ../../modules/common.nix
    ../../modules/network.nix
    ../../modules/power.nix
    ../../modules/storage.nix
    ../../modules/impermanence.nix
    ../../modules/security.nix
  ];

  # Hostname
  networking.hostName = "kafka";

  # Headless server (no GUI)
  head = false;

  # Legacy BIOS / MBR — GRUB installs to the disk MBR (no ESP)
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    efiSupport = false;
    useOSProber = false;
    configurationLimit = 10;
    # /boot is a btrfs subvolume; copyKernels avoids subvolume-relative path issues
    copyKernels = true;
  };

  # Firmware for hardware (network, etc.)
  hardware.enableRedistributableFirmware = true;

  # NVIDIA GT 630 (Kepler/GK208) — GPU is broken, using nomodeset (VESA/framebuffer only)
  # Blacklist all GPU drivers since GPU is non-functional
  boot.blacklistedKernelModules = [
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
    "nouveau"
    "amdgpu"
    "radeon"
  ];

  boot.kernelParams = [
    "nomodeset" # Disable kernel mode setting — uses basic VESA framebuffer
  ];

}
