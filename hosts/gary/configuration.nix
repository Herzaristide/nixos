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
    ../../modules/android.nix
  ];

  # Hostname
  networking.hostName = "gary";

  # SSH désactivé : seul kafka (serveur local) reste accessible en SSH.
  services.openssh.enable = lib.mkForce false;

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

  # /opt/rocm symlink — PyTorch/TensorFlow look for ROCm here by default
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  # ROCM_PATH — points ML frameworks to the ROCm installation
  environment.variables.ROCM_PATH = "${pkgs.rocmPackages.clr}";

  services.ollama.package = pkgs.ollama-rocm;
  environment.variables.HSA_OVERRIDE_GFX_VERSION = "11.0.0";

  services.ollama.environmentVariables = {
    OLLAMA_FLASH_ATTENTION = "1";
    OLLAMA_KV_CACHE_TYPE = "q8_0";
    OLLAMA_KEEP_ALIVE = "0";
  };

  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  # enable vient de modules/head.nix ; seul le chemin SMBus est spécifique.
  services.hardware.openrgb.motherboard = "amd"; # loads the AMD SMBus (i2c-piix4) path

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
