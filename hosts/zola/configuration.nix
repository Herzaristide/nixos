{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    ../../modules/nixos.nix
    ../../modules/common.nix
    ../../modules/network.nix
    ../../modules/initrd-ssh.nix
    ../../modules/power.nix
    ../../modules/storage.nix
    ../../modules/head.nix
    ../../modules/audio.nix
    ../../modules/security.nix
  ];

  # --- Battery / CPU power management (laptop, Intel) ---
  # Disable power-profiles-daemon (conflicts with auto-cpufreq)
  services.power-profiles-daemon.enable = lib.mkForce false;

  # Auto-cpufreq: dynamic CPU frequency scaling based on AC/battery state
  services.auto-cpufreq = {
    enable = true;
    settings = {
      # Battery: aggressive power saving
      battery = {
        governor = "powersave";
        turbo = "never"; # Disable turbo boost to reduce heat and power draw
        scaling_min_freq = 800000; # 800 MHz
        scaling_max_freq = 2400000; # Cap at 2.4 GHz
        enable_thresholds = true;
      };
      # AC: balanced performance
      charger = {
        governor = "performance";
        turbo = "auto";
        scaling_min_freq = 1200000;
        scaling_max_freq = 4000000;
      };
    };
  };

  # Thermald: Intel thermal management (prevents overheating, reduces fan noise)
  services.thermald.enable = true;

  # Powertop auto-tune on boot + powersave fallback governor
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "powersave";
    powertop.enable = true;
  };

  # Hostname
  networking.hostName = "zola";

  # MAC randomization on Wi-Fi (laptop carried to untrusted networks).
  # `stable` keeps a per-SSID MAC across associations (preserves DHCP reservations,
  # captive-portal sessions) while still preventing cross-network tracking.
  # `random` would generate a new MAC every connection — change to that if you
  # prefer privacy over reliability of DHCP/captive portals.
  networking.networkmanager.wifi.macAddress = "stable";
  networking.networkmanager.ethernet.macAddress = "stable";

  # Head configuration
  head = true;

  # Primary monitor: built-in screen (laptop)
  primaryMonitor = "eDP-1";

  # Bootloader (systemd-boot for UEFI; GRUB disabled)
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  # Ollama GPU acceleration — Prime Offload mode requires explicit NVIDIA env vars
  # Without these, the ollama systemd service runs on the Intel iGPU by default.
  services.ollama.package = pkgs.ollama-cuda;
  services.ollama.environmentVariables = {
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __VK_LAYER_NV_OPTIMUS = "NVIDIA_only";
  };
}
