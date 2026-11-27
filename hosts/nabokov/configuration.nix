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
    # Pas d'ollama local : 8 Go de RAM, 4 Gio de VRAM au plus — nabokov se sert
    # de celui de gary (OLLAMA_HOST=gary:11434).
    ../../modules/print.nix
  ];

  # Hostname
  networking.hostName = "nabokov";

  # --- Accès : nabokov reçoit du SSH de bernanos, n'en émet vers personne ---
  #
  # Copie de bernanos, sauf pour SSH :
  #   - entrant : sshd, sur tailscale0 seulement, et seulement depuis bernanos ;
  #   - sortant : nabokov n'a aucune clé, et gary/kafka n'en autorisent aucune
  #     de nabokov — il n'a donc accès à rien en SSH. Il n'utilise gary que par
  #     ses endpoints HTTP sur le tailnet (ComfyUI 8188, ollama 11434).

  services.openssh = {
    enable = true;
    # Pas de port 22 sur le LAN/Wi-Fi : tailscale.nix l'ouvre sur tailscale0.
    openFirewall = false;
    # Seul bernanos (IP tailnet, cf. home/modules/network/ssh.nix) peut se
    # connecter, avec les clés de modules/common.nix.
    settings.AllowUsers = [ "aristide@100.67.220.15" ];
  };

  # Pas de client SSH utilisable : ni agent, ni entrées d'hôte (gary, kafka,
  # bernanos, GitHub — git passe par HTTPS via gh/glab). Ne jamais copier
  # siddhartha ni aucune clé privée sur cette machine ; gary et kafka n'ont
  # d'ailleurs aucune clé de nabokov dans leurs authorized_keys.
  home-manager.users.aristide = {
    services.ssh-agent.enable = lib.mkForce false;
    programs.ssh.settings = lib.mkForce { };
  };

  # Matériel (relevé le 2026-11-27) : HP OMEN 15 (carte 8259), i5-7300HQ
  # (Kaby Lake, 4c/4t), 8 Go, Intel HD 630 + GeForce GTX 1050 Mobile (Pascal,
  # GP107), SSD SATA Samsung 128 Go (sda) + HDD HGST 1 To (sdb, non utilisé),
  # Wi-Fi Intel 7265, Ethernet RTL8111. UEFI.

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
        scaling_max_freq = 3500000; # turbo max du i5-7300HQ
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
  # 8 Go de RAM.
  nix.settings.max-jobs = lib.mkForce 1;

  # --- GPU (NVIDIA GTX 1050 Mobile, Prime Intel+Nvidia, Wayland) ---
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

  nixpkgs.config.nvidia.acceptLicense = true;

  hardware = {
    nvidia = {
      open = false; # Pascal : les modules ouverts exigent Turing ou plus récent
      # NVIDIA a arrêté Maxwell/Pascal/Volta après la branche 580 : le pilote
      # par défaut de nixpkgs (595) ne gère plus la GTX 1050.
      package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
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
                echo "gpu_info{pci=\"$pci\",vendor=\"nvidia\",name=\"GeForce GTX 1050 Mobile\",state=\"$state\"} 1"
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
