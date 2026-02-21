{ config, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    inputs.dms.nixosModules.greeter
    ../../modules/common.nix
    ../../modules/head.nix
  ];

  # Hostname
  networking.hostName = "gary";

  # Head configuration
  head = true;

  # Bootloader (systemd-boot for UEFI; GRUB disabled)
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.networkmanager.enable = true;


  # SSH - allow password authentication
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # --- GPU (NVIDIA GeForce GT 630 Rev. 2, GK208 / Kepler) — nouveau ---
  # Proprietary NVIDIA 470 crashes Hyprland (initDRMFormats); nouveau has proper GBM/Wayland support
  # Nouveau firmware load failures (msvld -19) cause stuck kworkers and phantom iowait

  # Firmware: provide linux-firmware blobs so nouveau doesn't stall on missing firmware
  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  boot.blacklistedKernelModules = [ "nvidia" "nvidia_drm" "nvidia_modeset" "nvidia_uvm" ];

  # Tell nouveau not to attempt loading signed firmware for video engines (Kepler)
  boot.kernelParams = [ "nouveau.config=NvGrUseFW=0" ];

  # modesetting DDX uses nouveau kernel DRM but avoids the legacy nouveau DDX driver
  services.xserver.videoDrivers = [ "modesetting" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # SSD maintenance — periodic TRIM
  services.fstrim.enable = true;

  # Nix experimental features
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

}