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
    ../../modules/storage.nix
    ../../modules/head.nix
    ../../modules/audio.nix
    ../../modules/bluetooth.nix
    ../../modules/security.nix
    ../../modules/android.nix
  ];

  # Hostname
  networking.hostName = "gary";

  # Enable GUI (Hyprland/DMS)
  head = true;

  # Primary monitor: Samsung C27R50x (DP-1)
  primaryMonitor = "DP-1";

  # Bootloader (systemd-boot for UEFI; GRUB disabled)
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # CPU: AMD Ryzen 5 7600X (Zen 4 / Raphael, 6c/12t, AM5)
  # amd-pstate (EPP) is used automatically on modern kernels — no governor override.
  boot.kernelModules = [ "kvm-amd" ]; # AMD-V virtualization (KVM, QEMU, libvirt)
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # GPU: AMD Radeon RX 7600 XT (RDNA 3 / Navi 33, gfx1102) — amdgpu driver.
  # The Ryzen 7600X also exposes a Raphael RDNA2 iGPU (gfx1036); both are
  # driven by amdgpu, the discrete card handles display + compute.
  services.xserver.videoDrivers = [ "amdgpu" ];

  # Load amdgpu early for seamless KMS (no flicker at boot)
  boot.initrd.kernelModules = [ "amdgpu" ];

  # Hardware-accelerated graphics (Vulkan, OpenGL, VA-API, OpenCL via ROCm)
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # 32-bit support for Wine/games
    extraPackages = with pkgs; [
      rocmPackages.clr.icd # OpenCL ICD entry for ROCm
    ];
  };

  # ROCm — GPU compute stack for machine learning (PyTorch, TensorFlow, etc.)
  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-smi # GPU monitoring & management
    rocmPackages.rocminfo # GPU info / capability query
    rocmPackages.clr # HIP runtime + OpenCL (Compute Language Runtime)
    rocmPackages.rocm-runtime # HSA runtime (low-level ROCm layer)
    rocmPackages.hipcc # HIP compiler (GPU kernel compilation)
    zenmonitor # CPU monitoring (per-CCX temps, P-states, boost)
  ];

  # /opt/rocm symlink — PyTorch/TensorFlow look for ROCm here by default
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  # ROCM_PATH — points ML frameworks to the ROCm installation
  environment.variables.ROCM_PATH = "${pkgs.rocmPackages.clr}";

  # Ollama GPU acceleration — use AMD ROCm.
  # The RX 7600 XT is Navi 33 / gfx1102, but upstream rocBLAS in nixpkgs ships
  # Tensile kernels for the RDNA3 flagship arch gfx1100, not gfx1102.
  # HSA_OVERRIDE_GFX_VERSION=11.0.0 exposes the GPU as gfx1100 so rocBLAS finds
  # its kernels — works straight from the binary cache, no local rebuild. We
  # keep the override explicit so every ROCm consumer on this host (Ollama,
  # PyTorch, etc.) gets the same arch mapping.
  services.ollama.package = pkgs.ollama-rocm;
  environment.variables.HSA_OVERRIDE_GFX_VERSION = "11.0.0";

  # Optimisations mémoire VRAM pour la RX 7600 XT (16 Go) :
  #   - Flash Attention : attention plus économe en VRAM et plus rapide.
  #   - KV cache quantifié en q8_0 : divise ~par 2 l'empreinte du cache de
  #     contexte → contextes plus longs (ou modèle un peu plus gros) à VRAM
  #     égale. q8_0 = quasi aucune perte de qualité vs f16.
  #   - KEEP_ALIVE = 0 : décharge le modèle de la VRAM dès la fin de chaque
  #     requête. Évite le coil whine du GPU quand un modèle reste chargé au
  #     repos ; contrepartie = rechargement (~quelques secondes) à la requête
  #     suivante.
  services.ollama.environmentVariables = {
    OLLAMA_FLASH_ATTENTION = "1";
    OLLAMA_KV_CACHE_TYPE = "q8_0";
    OLLAMA_KEEP_ALIVE = "0";
  };

  # RGB lighting — OpenRGB (fans, RAM, GPU, USB controllers)
  # Detected on this host:
  #   - B650 GAMING X AX V2 motherboard (ITE IT5701) — USB HID (/dev/hidraw*),
  #     drives the 12V/ARGB headers (case fans, strips)
  #   - Corsair Dominator Platinum RAM — SMBus (i2c-piix4, 0x19/0x1B)
  # NOT controllable on Linux:
  #   - Gigabyte RX 7600 XT (RGB Fusion) — amdgpu does not expose the GPU's
  #     internal i2c bus (only the display-connector DDC buses), so OpenRGB
  #     cannot reach the GPU RGB controller. Set it once from Windows/BIOS;
  #     the controller keeps its state. No RDNA3 kernel workaround exists.
  # The module installs the openrgb package (GUI + CLI), loads i2c-dev so the
  # SMBus RAM/GPU controllers are visible, sets the udev hidraw rules for the
  # USB devices, and runs the openrgb server as a systemd service.
  #
  # acpi_enforce_resources=lax is REQUIRED for SMBus RGB (RAM/GPU/fan ctrl):
  # by default the kernel (strict) lets ACPI reserve the FCH SMBus I/O region,
  # so i2c_piix4 silently refuses to register an adapter and OpenRGB only sees
  # the USB motherboard controller. "lax" lets the driver claim the bus too.
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  services.hardware.openrgb = {
    enable = true;
    motherboard = "amd"; # loads the AMD SMBus (i2c-piix4) path
  };

  # ── RAM + case fans follow the accent colour ────────────────────────────────
  # The paletted daemon writes the current accent to ~/.config/accent/accent.hex
  # on every change; a path unit re-applies it to OpenRGB here. One invocation
  # drives two devices:
  #   - Case fans on the motherboard D_LED1 header = zone 1 of the
  #     "B650 GAMING X AX V2" device. `static` stores the colour in the ITE
  #     controller so it survives even when openrgb isn't running (before login).
  #     The zone size must be re-sent every apply: the openrgb *server* resets
  #     zone sizes to their default on (re)start, and the fan has more LEDs than
  #     that default (otherwise only part of the ring gets coloured).
  #   - Corsair Dominator Platinum RAM (both sticks share the name, so a single
  #     `-d` covers both). The Corsair DRAM controller only offers `Direct`, with
  #     no persistent hardware mode — the sticks hold the last Direct frame while
  #     powered but reset on power loss, so this service re-applies at every boot
  #     (it runs After=openrgb.service).
  systemd.services.openrgb-accent = {
    description = "Apply the accent colour to the OpenRGB RAM + case fans";
    after = [ "openrgb.service" ];
    wants = [ "openrgb.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "openrgb-accent" ''
        set -u
        hexfile=/home/aristide/.config/accent/accent.hex
        [ -r "$hexfile" ] || { echo "openrgb-accent: no accent.hex yet, skipping" >&2; exit 0; }
        hex=$(${pkgs.coreutils}/bin/tr -d '#[:space:]' < "$hexfile")
        case "$hex" in
          [0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) ;;
          *) echo "openrgb-accent: invalid accent '$hex', skipping" >&2; exit 0 ;;
        esac
        # The server may not have finished device detection right after start.
        for _ in 1 2 3 4 5; do
          if ${config.services.hardware.openrgb.package}/bin/openrgb \
               -d "Corsair Dominator Platinum" -m direct -c "$hex" \
               -d "B650 GAMING X AX V2" -z 1 -sz 30 -m static -c "$hex"; then
            exit 0
          fi
          ${pkgs.coreutils}/bin/sleep 2
        done
        echo "openrgb-accent: apply failed after retries" >&2
        exit 0
      '';
    };
  };

  systemd.paths.openrgb-accent = {
    description = "Re-apply the OpenRGB RGB colour when the accent changes";
    pathConfig.PathModified = "/home/aristide/.config/accent/accent.hex";
    wantedBy = [ "multi-user.target" ];
  };

}
