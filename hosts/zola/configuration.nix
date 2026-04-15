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
    ../../modules/common.nix
    ../../modules/head.nix
    ../../modules/battery-optimization.nix
  ];

  # Hostname
  networking.hostName = "zola";

  # Head configuration
  head = true;

  # Bootloader (systemd-boot for UEFI; GRUB disabled)
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Networking
  networking.networkmanager.enable = true;

  # Lid close handling: don't suspend when docked with external monitors
  # When lid is closed, systemd-logind will ignore it (Hyprland handles display disable)
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore"; # Don't suspend on lid close (let Hyprland handle it)
    HandleLidSwitchDocked = "ignore"; # Also ignore when docked
    HandleLidSwitchExternalPower = "ignore"; # Ignore when on AC power
  };

  # SSH - allow password authentication
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # --- GPU (NVIDIA, Zola: Prime Intel+Nvidia, Wayland) ---
  boot.kernelParams = [
    "nvidia-drm.modeset=1" # Enable mode setting for Wayland
    # "nvidia_drm.fbdev=1" # Enable framebuffer device (crucial for Wayland)
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # Improves resume after sleep
    # Power optimizations: favor battery life over performance
    # PowerMizerLevel=0x3 → Adaptive (auto-adjust based on load)
    # PowerMizerDefault=0x3 → Adaptive on battery
    "nvidia.NVreg_RegistryDwords=PowerMizerEnable=0x1;PerfLevelSrc=0x3333;PowerMizerLevel=0x3;PowerMizerDefault=0x3;PowerMizerDefaultAC=0x1"
  ];
  boot.blacklistedKernelModules = [ "nouveau" ];

  # X11 video drivers
  services.xserver.videoDrivers = [ "nvidia" ];

  # Environment variables for NVIDIA + Intel VA-API for video (Chrome, etc.)
  environment.variables = {
    LIBVA_DRIVER_NAME = "iHD"; # Use Intel iGPU for video decode - avoids nvidia-vaapi bugs in Chrome
    XDG_SESSION_TYPE = "wayland"; # Force Wayland
    GBM_BACKEND = "nvidia-drm"; # Graphics backend for Wayland
    __GLX_VENDOR_LIBRARY_NAME = "nvidia"; # Use Nvidia driver for GLX
    WLR_NO_HARDWARE_CURSORS = "1"; # Fix for cursors on Wayland
    NIXOS_OZONE_WL = "1"; # Wayland support for Electron apps
    __GL_GSYNC_ALLOWED = "1"; # Enable G-Sync if available
    __GL_VRR_ALLOWED = "1"; # Enable VRR (Variable Refresh Rate)
    WLR_DRM_NO_ATOMIC = "1"; # Fix for some issues with Hyprland
    NVD_BACKEND = "direct"; # Configuration for new driver
  };

  # NVIDIA proprietary drivers
  nixpkgs.config = {
    nvidia.acceptLicense = true;
  };

  hardware = {
    nvidia = {
      open = false; # Proprietary driver for better performance
      nvidiaSettings = true; # Nvidia settings utility
      powerManagement = {
        enable = true; # Power management
        finegrained = true; # Fine-grained power control (required for offload mode)
      };
      modesetting.enable = true; # Required for Wayland
      # package = nvidiaDriverChannel; # Uncomment and define if using custom driver channel
      forceFullCompositionPipeline = true; # Prevents screen tearing

      # Configuration for hybrid Intel+Nvidia laptop
      prime = {
        # OFFLOAD MODE: Intel iGPU by default, NVIDIA on-demand (massive battery savings)
        # Use `nvidia-offload <command>` to run apps on NVIDIA (e.g., nvidia-offload steam)
        offload = {
          enable = true; # Mode optimized for power saving
          enableOffloadCmd = true; # Creates nvidia-offload wrapper command
        };
        # Sync mode disabled: it keeps NVIDIA always powered (kills battery)
        sync.enable = false;
        # PCI IDs verified for your hardware
        intelBusId = "PCI:0:2:0"; # Integrated Intel GPU
        nvidiaBusId = "PCI:1:0:0"; # Dedicated Nvidia GPU
      };
    };

    # Enhanced graphics support
    graphics = {
      enable = true;
      # package = nvidiaDriverChannel; # Uncomment and define if using custom driver channel
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver # Chrome video decode on Intel iGPU (avoids nvidia-vaapi bugs)
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
        mesa
        egl-wayland
        vulkan-loader
        vulkan-validation-layers
        libva
      ];
    };
  };

  # System packages for NVIDIA
  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
    libva-utils
  ];

  # Nix cache for CUDA
  nix.settings = {
    substituters = [ "https://cuda-maintainers.cachix.org" ];
    trusted-public-keys = [
      "cuda-maintainers.cachix.org-1:0dq3bujKpuEPMCX6U4WylrUDZ9JyUG0VpVZa7CNfq5E="
    ];
  };
}
