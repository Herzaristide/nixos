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
    ../../modules/greetd.nix
    ../../modules/audio.nix
    ../../modules/bluetooth.nix
    ../../modules/security.nix
    # ../../modules/android.nix  # test : déplacement vers un devShell par projet
    ../../modules/impermanence.nix
    ../../modules/print.nix
  ];

  # Hostname
  networking.hostName = "gary";

  # Enable GUI (Hyprland/DMS)
  head = true;

  primaryMonitor = "HDMI-A-3";

  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # CPU: AMD Ryzen 5 7600X (Zen 4 / Raphael, 6c/12t, AM5)
  # amd-pstate (EPP) is used automatically on modern kernels — no governor override.
  boot.kernelModules = [ "kvm-amd" ]; # AMD-V virtualization (KVM, QEMU, libvirt)
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.rasdaemon.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  renderDevice = "/dev/dri/by-path/pci-0000:13:00.0-card";
  nixpkgs.config.rocmSupport = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd # OpenCL ICD entry for ROCm
    ];
  };

  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-smi
    rocmPackages.rocminfo
    rocmPackages.clr
    rocmPackages.rocm-runtime
    rocmPackages.hipcc
    zenmonitor
  ];

  # Vérité matérielle de la machine, pas une préférence de projet : la RX 7600 XT
  # est gfx1102, mais rocBLAS ne livre ses kernels Tensile que pour gfx1100.
  # ROCM_PATH et /opt/rocm, eux, ont été retirés — c'est aux devShells des
  # projets pip/Docker de déclarer où ils trouvent ROCm.
  environment.variables.HSA_OVERRIDE_GFX_VERSION = "11.0.0";

  services.ollama.environmentVariables = {
    OLLAMA_FLASH_ATTENTION = "1";
    OLLAMA_KV_CACHE_TYPE = "q8_0";
    OLLAMA_KEEP_ALIVE = "0";
  };

  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  # enable vient de modules/head.nix ; seul le chemin SMBus est spécifique.
  services.hardware.openrgb.motherboard = "amd"; # loads the AMD SMBus (i2c-piix4) path

}
