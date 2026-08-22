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

  # Wifi MediaTek MT7922 (mt7921e, PCI 09:00.0) — bug matériel/firmware connu et
  # intermittent : après un reboot à chaud, le chip reste parfois bloqué dans un
  # état d'où l'hôte ne peut pas reprendre la « propriété » du firmware. Le boot
  # échoue alors avec « driver own failed » puis « probe failed with error -5 »,
  # et aucune interface wlp9s0 n'est créée → pas de wifi ce boot-là.
  #   - Fréquence observée : ~1 boot sur 10 réellement KO (2026-07-24) ; se résout
  #     tout seul au boot suivant (cold boot ou simple retry du driver).
  #   - Diagnostic : `journalctl -b -1 -k | grep -iE 'driver own|mt7921'`.
  #   - Rien d'activé pour l'instant (occurrence isolée, pas de régression config).
  #     Si ça devient récurrent, la mitigation habituelle est de couper l'ASPM PCIe :
  #     ajouter "pcie_aspm=off" (global, ↑conso) ou "pci=noaspm" aux kernelParams.
  boot.kernelParams = [ "acpi_enforce_resources=lax" ];
  # `enable` était dans modules/head.nix ; rapatrié ici (zola n'a aucun
  # périphérique qu'OpenRGB reconnaisse, cf. le commentaire là-bas).
  services.hardware.openrgb.enable = true;
  services.hardware.openrgb.motherboard = "amd"; # loads the AMD SMBus (i2c-piix4) path

}
