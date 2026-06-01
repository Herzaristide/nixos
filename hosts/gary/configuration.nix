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
    ../../modules/luks-usb-key.nix
    ../../modules/power.nix
    ../../modules/storage.nix
    ../../modules/head.nix
    ../../modules/audio.nix
    ../../modules/security.nix
    ../../modules/voice.nix
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

  # Firmware for hardware (network, etc.)
  hardware.enableRedistributableFirmware = true;

  # CPU: AMD Ryzen 5 1600 (Zen 1 / Summit Ridge, 6c/12t, AM4)
  # Microcode update is enabled via hardware-configuration.nix (cpu.amd.updateMicrocode)
  boot.kernelModules = [ "kvm-amd" ]; # AMD-V virtualization (KVM, QEMU, libvirt)

  # GPU: AMD Radeon RX 6600 (RDNA 2 / Navi 23) — amdgpu driver
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
  # The RX 6600 is gfx1032 but upstream rocBLAS in nixpkgs ships kernels for
  # gfx1030 (and family), not gfx1032. Ollama 0.23 auto-sets
  # HSA_OVERRIDE_GFX_VERSION=10.3.0 for the gfx103x family, so HSA exposes the
  # GPU as gfx1030 and rocBLAS finds its Tensile kernels — works from the
  # binary cache, no local rebuild. We keep the override explicit so other
  # ROCm consumers on this host (PyTorch, etc.) get the same arch mapping.
  services.ollama.package = pkgs.ollama-rocm;
  environment.variables.HSA_OVERRIDE_GFX_VERSION = "10.3.0";

}
