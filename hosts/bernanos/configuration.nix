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
    ../../modules/tailscale.nix
    ../../modules/node-exporter.nix
    ../../modules/power.nix
    ../../modules/zram.nix
    ../../modules/storage.nix
    ../../modules/head.nix
    ../../modules/greetd.nix
    ../../modules/nautilus.nix
    ../../modules/audio.nix
    ../../modules/bluetooth.nix
    ../../modules/security.nix
    # ../../modules/android.nix  # test : déplacement vers un devShell par projet
    ../../modules/impermanence.nix
    ../../modules/ollama.nix
    ../../modules/print.nix
  ];

  # Hostname
  networking.hostName = "bernanos";

  # Primary monitor: built-in screen (laptop)
  primaryMonitor = "eDP-1";

  # Bootloader (systemd-boot for UEFI; GRUB disabled)
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # CPU: Intel — KVM virtualization + microcode update
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Mises à jour BIOS/firmware via LVFS (`fwupdmgr update`).
  services.fwupd.enable = true;

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

  # `powertop --auto-tune` passe tous les périphériques USB en autosuspend
  # (power/control=auto) avec le délai kernel par défaut de 2 s : le récepteur
  # du clavier Logitech s'endormait à chaque pause et retenait les frappes
  # ~2 s au réveil. powertop ne touche qu'à `control`, pas au délai : on
  # rallonge donc celui-ci à 5 min, au branchement, pour le récepteur Logitech
  # et le dongle de la souris Corsair Katar Pro.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c548", ATTR{power/autosuspend_delay_ms}="300000"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1b1c", ATTR{idProduct}=="1b94", ATTR{power/autosuspend_delay_ms}="300000"
  '';

  # Fermer le capot suspend réellement la machine (modules/power.nix l'ignore
  # par défaut). hypridle (home/modules/hyprland/lock.nix) verrouille déjà
  # l'écran via before_sleep_cmd avant toute mise en veille, donc fermer le
  # capot verrouille aussi la session, pas seulement l'écran.
  services.logind.settings.Login.HandleLidSwitch = lib.mkForce "suspend";

  # Un seul build à la fois (au lieu de 2 × 6 cœurs, modules/nixos.nix) :
  # un build CUDA à côté d'un autre gros build ne tient pas dans 16 Go.
  nix.settings.max-jobs = lib.mkForce 1;

  # --- GPU (NVIDIA, Bernanos: Prime Intel+Nvidia, Wayland) ---
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
  # CUDA à la carte, pas de `cudaSupport` global. `cudaCapabilities` limite
  # toute compilation CUDA à la seule arch sm_86 (RTX 3070 Mobile) ; sans
  # paquet CUDA dans la closure il ne change rien (ollama-cuda, plus bas).
  nixpkgs.config = {
    nvidia.acceptLicense = true;
    cudaCapabilities = [ "8.6" ];
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

  # PRIME offload : sans ces variables le service ollama tourne sur l'iGPU
  # Intel, qui reste le GPU par défaut. Ce sont exactement celles qu'exporte le
  # wrapper `nvidia-offload` de nixpkgs (nixos/modules/hardware/video/nvidia.nix)
  # — noter le casse mixte de `__VK_LAYER_NV_optimus`, seule graphie reconnue
  # par le driver.
  #
  # ollama CUDA : `pkgs.ollama-cuda` (pas de `cudaSupport` global), ciblé sur
  # sm_86 par `cudaCapabilities` — compile en local (aucun cache CUDA).
  #
  # Le service lui-même : modules/ollama.nix.
  services.ollama.package = pkgs.ollama-cuda;
  # 8 Gio de VRAM (RTX 3070 Mobile) et ~5 Go de RAM libre en session : rien
  # au-delà de ~7 Go. Tailles relevées le 2026-11-19, ~16 Go au total. Les
  # gros modèles se demandent à gary (OLLAMA_HOST=gary:11434).
  services.ollama.loadModels = [
    "qwen3.5:9b" # 6,6 Go — polyvalent, code
    "gemma4:e4b" # 6,6 Go — léger, lit les images, bon en français
    "qwen3.5:4b" # 3,3 Go — rapide, laisse de la VRAM libre
    # "qwen3:8b" # 5,2 Go
    # "llama3.1:8b" # 4,9 Go
  ];
  services.ollama.environmentVariables = {
    # Le pilote de karenine (anna) envoie ~5 300 tokens avant le premier mot
    # (prompt + 32 outils) : avec le contexte par défaut (4096), ollama en
    # jetait la moitié sans rien dire (mesuré le 2026-11-20). À 16k,
    # qwen3.5:9b tient entièrement dans les 8 Gio (5,6 Gio) ; à 32k il
    # déborde sur le CPU (85 % en VRAM).
    OLLAMA_CONTEXT_LENGTH = "16384";
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __NV_PRIME_RENDER_OFFLOAD_PROVIDER = "NVIDIA-G0";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __VK_LAYER_NV_optimus = "NVIDIA_only";
  };

  # GPU pour node_exporter (gpu.prom, à côté de l'extras.prom de
  # modules/node-exporter.nix), lu par anna. nvidia-smi réveille toujours la
  # carte : on ne l'appelle que si sysfs la dit déjà éveillée.
  systemd.services.gpu-metrics = {
    description = "GPU NVIDIA pour node_exporter (anna)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${
        lib.getExe (
          pkgs.writeShellApplication {
            name = "gpu-metrics";
            # nvidia-smi du pilote installé.
            runtimeInputs = [
              pkgs.coreutils
              config.hardware.nvidia.package.bin
            ];
            text = ''
              # L'état vient de sysfs, qui ne réveille pas la carte ; nvidia-smi seulement si elle est déjà éveillée.
              dir=$1
              pci=0000:01:00.0
              state=$(cat "/sys/bus/pci/devices/$pci/power/runtime_status" 2>/dev/null || echo active)
              {
                echo "gpu_info{pci=\"$pci\",vendor=\"nvidia\",name=\"GeForce RTX 3070 Mobile\",state=\"$state\"} 1"
                if [ "$state" = active ]; then
                  nvidia-smi --id="$pci" --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu \
                    --format=csv,noheader,nounits 2>/dev/null \
                    | while IFS=', ' read -r busy used total temp; do
                        case "$busy$used$total$temp" in *[!0-9]*) continue ;; esac
                        echo "gpu_busy_percent{pci=\"$pci\"} $busy"
                        echo "gpu_vram_used_bytes{pci=\"$pci\"} $((used * 1048576))"
                        echo "gpu_vram_total_bytes{pci=\"$pci\"} $((total * 1048576))"
                        echo "gpu_temp_celsius{pci=\"$pci\"} $temp"
                      done
                fi
              } > "$dir/gpu.prom.tmp"
              chmod 644 "$dir/gpu.prom.tmp"
              mv "$dir/gpu.prom.tmp" "$dir/gpu.prom"
            '';
          }
        )
      } /run/node-exporter";
      ReadWritePaths = [ "/run/node-exporter" ];
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  systemd.timers.gpu-metrics = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5s";
      OnUnitActiveSec = "15s";
      AccuracySec = "1s";
    };
  };
}
