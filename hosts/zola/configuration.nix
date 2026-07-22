{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.home-manager.nixosModules.default
    ../../modules/nixos.nix
    ../../modules/common.nix
    ../../modules/kernel.nix
    ../../modules/network.nix
    ../../modules/power.nix
    ../../modules/zram.nix
    ../../modules/storage.nix
    ../../modules/head.nix
    ../../modules/greetd.nix
    ../../modules/audio.nix
    ../../modules/bluetooth.nix
    ../../modules/security.nix
    # ../../modules/android.nix  # test : déplacement vers un devShell par projet
    ../../modules/impermanence.nix
    ../../modules/print.nix
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

  # CPU: Intel — KVM virtualization + microcode update
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Hostname
  networking.hostName = "zola";

  # Fermer le capot suspend réellement la machine (modules/power.nix l'ignore
  # par défaut, pertinent seulement ici — zola est le seul hôte avec un capot).
  # hypridle (home/modules/hyprland/hyprlock.nix) verrouille déjà l'écran via
  # before_sleep_cmd avant toute mise en veille, donc fermer le capot verrouille
  # aussi la session, pas seulement l'écran.
  services.logind.settings.Login.HandleLidSwitch = lib.mkForce "suspend";

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
    # NIXOS_OZONE_WL is set in modules/head.nix (shared by all headful hosts).
    __GL_GSYNC_ALLOWED = "1"; # Enable G-Sync if available
    __GL_VRR_ALLOWED = "1"; # Enable VRR (Variable Refresh Rate)
    WLR_DRM_NO_ATOMIC = "1"; # Fix for some issues with Hyprland
    NVD_BACKEND = "direct"; # Configuration for new driver
  };

  # NVIDIA proprietary drivers.
  # Pas de `cudaSupport` global : il recompilait ~29 paquets absents du cache
  # cuda-maintainers. CUDA est activé à la carte — ollama-cuda (pré-buildé) et
  # blender via l'overlay ci-dessous.
  nixpkgs.config.nvidia.acceptLicense = true;
  nixpkgs.overlays = [
    (final: prev: {
      blender = prev.blender.override { cudaSupport = true; };
    })
  ];

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
        # Use `nvidia-offload <command>` to run apps on NVIDIA (e.g., nvidia-offload glxgears)
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

  # PRIME offload : sans ces variables le service ollama tourne sur l'iGPU
  # Intel, qui reste le GPU par défaut. Ce sont exactement celles qu'exporte le
  # wrapper `nvidia-offload` de nixpkgs (nixos/modules/hardware/video/nvidia.nix)
  # — noter le casse mixte de `__VK_LAYER_NV_optimus`, seule graphie reconnue
  # par le driver.
  #
  # Variante CUDA pré-buildée (cuda-maintainers), surcharge le pkgs.ollama de common.nix.
  services.ollama.package = pkgs.ollama-cuda;
  services.ollama.environmentVariables = {
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __VK_LAYER_NV_optimus = "NVIDIA_only";
  };
}
