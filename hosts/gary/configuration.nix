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
    ../../modules/head.nix
    ../../modules/audio.nix
    ../../modules/security.nix
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

  # CPU governor is set to "performance" by DMS base.nix — appropriate for a plugged-in desktop.
  # Note: amd-pstate is NOT used (requires Zen 2+ with CPPC); acpi-cpufreq remains the driver.

  # zram swap — fast in-memory compressed swap (Zen 1 has plenty of cycles for zstd)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

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

  # Restrict ROCm builds to this host's GPU (RX 6600 / Navi 23 / gfx1032).
  # Without this, rocBLAS/Tensile generate kernels for every supported arch
  # (gfx900..gfx1100), which is what causes "Loading Logics... N/2043" to crawl.
  # Downside: derivation hashes diverge from Hydra → no binary cache hit.
  nixpkgs.overlays = [
    (
      final: prev:
      let
        gfx = [ "gfx1032" ];
        rocmPackages' = prev.rocmPackages.overrideScope (
          rocmFinal: rocmPrev: {
            clr = rocmPrev.clr.override { localGpuTargets = gfx; };
            rocblas = rocmPrev.rocblas.override { gpuTargets = gfx; };
            rocsparse = rocmPrev.rocsparse.override { gpuTargets = gfx; };
            rocfft = rocmPrev.rocfft.override { gpuTargets = gfx; };
            hipblaslt = rocmPrev.hipblaslt.override { gpuTargets = gfx; };
            # miopen skipped: depends on composable_kernel which is marked broken for gfx1032.
            rocrand = rocmPrev.rocrand.override { gpuTargets = gfx; };
            rocsolver = rocmPrev.rocsolver.override { gpuTargets = gfx; };
          }
        );
      in
      {
        rocmPackages = rocmPackages';
        ollama-rocm = prev.ollama-rocm.override {
          rocmGpuTargets = gfx;
          rocmPackages = rocmPackages';
        };
      }
    )
  ];

  # Ollama GPU acceleration — use AMD ROCm (RX 6600 / gfx1032)
  services.ollama.package = pkgs.ollama-rocm;
  services.ollama.rocmOverrideGfx = "10.3.0"; # Navi 23 / gfx1032

}
