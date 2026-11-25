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
    ../../modules/bluetooth.nix
    ../../modules/security.nix
    ../../modules/luks-usb-key.nix
    ../../modules/impermanence.nix
    ../../modules/comfyui.nix
    ../../modules/ollama.nix
    ../../modules/k3s.nix
  ];

  # Hostname
  networking.hostName = "gary";

  # sshd actif sur les serveurs seulement (désactivé par défaut, modules/network.nix).
  services.openssh.enable = true;

  # Clé d'exupery : n'ouvre que les serveurs de dev (ici et kafka), pas les autres hôtes ni GitHub.
  users.users.aristide.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILxa24l5t4C9ZHBE6NDE823vui27oYX2bQuTLtDY3lY/ aristide@exupery"
  ];

  # Serveur de dev headless : ni greetd, ni Hyprland, ni PipeWire.
  # Accès par SSH / Tailscale uniquement.
  head = false;

  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Sans session ouverte, le manager systemd utilisateur ne tourne pas : Docker
  # rootless et les services utilisateur n'attendraient pas le premier login.
  users.users.aristide.linger = true;

  # CPU: AMD Ryzen 5 7600X (Zen 4 / Raphael, 6c/12t, AM5)
  # amd-pstate (EPP) is used automatically on modern kernels — no governor override.
  boot.kernelModules = [ "kvm-amd" ]; # AMD-V virtualization (KVM, QEMU, libvirt)
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.rasdaemon.enable = true;
  services.xserver.videoDrivers = [ "amdgpu" ];
  boot.initrd.kernelModules = [ "amdgpu" ];
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
    stable-diffusion-cpp-rocm # sd-cli : génération d'images en C++/HIP, sans Python
  ];

  # Vérité matérielle de la machine, pas une préférence de projet : la RX 7600 XT
  # est gfx1102, mais rocBLAS ne livre ses kernels Tensile que pour gfx1100.
  # ROCM_PATH et /opt/rocm, eux, ont été retirés — c'est aux devShells des
  # projets pip/Docker de déclarer où ils trouvent ROCm.
  environment.variables.HSA_OVERRIDE_GFX_VERSION = "11.0.0";

  # ollama (service : modules/ollama.nix) sur la RX 7600 XT. La variable
  # globale ci-dessus ne s'applique pas aux services systemd : rocmOverrideGfx
  # pose HSA_OVERRIDE_GFX_VERSION pour lui, et HIP_VISIBLE_DEVICES écarte
  # l'iGPU Raphael (gfx1036), qui sous l'override serait pris pour un gfx1100.
  # KEEP_ALIVE = 0 : le modèle quitte la VRAM aussitôt la réponse donnée, pour
  # la laisser à ComfyUI, qui partage la carte.
  #
  # Exposé au tailnet comme ComfyUI (modules/comfyui.nix) : le service écoute
  # sur 0.0.0.0, mais le port 11434 n'est ouvert que sur tailscale0 — rien sur
  # le LAN. ollama n'a aucune authentification : tout appareil du tailnet peut
  # l'interroger, télécharger ou supprimer des modèles.
  services.ollama = {
    host = "0.0.0.0";
    package = pkgs.ollama-rocm;
    rocmOverrideGfx = "11.0.0";
    environmentVariables = {
      HIP_VISIBLE_DEVICES = "0";
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
      OLLAMA_KEEP_ALIVE = "0";
    };
  };
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [
    config.services.ollama.port
  ];

  # Modèles ollama, tirés du registre au démarrage (modules/ollama.nix).
  # 16 Gio de VRAM, partagés avec ComfyUI ; au-delà de ~14 Go le modèle
  # déborde sur la RAM, ce qui ne reste rapide que pour les MoE (peu de
  # paramètres actifs). Tailles relevées le 2026-11-19, ~47 Go au total.
  services.ollama.loadModels = [
    "gpt-oss:20b" # 13,8 Go — raisonnement, effort réglable ; MoE, tient en VRAM
    "qwen3.5:9b" # 6,6 Go — polyvalent rapide, long contexte
    "gemma4:12b" # 8,0 Go — polyvalent, lit les images, bon en français
    "qwen3-coder:30b" # 18,6 Go — code ; MoE 3B actifs, déborde ~4 Go en RAM
    # "qwen3.6:35b-a3b" # 22,6 Go — MoE plus récent, déborde ~8 Go
    # "gemma4:26b" # 18,7 Go
    # "qwen3.6:27b" # 17,8 Go — dense : lent dès qu'il déborde
  ];

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
  # `enable` était dans modules/head.nix ; rapatrié ici (bernanos n'a aucun
  # périphérique qu'OpenRGB reconnaisse, cf. le commentaire là-bas).
  services.hardware.openrgb.enable = true;
  services.hardware.openrgb.motherboard = "amd"; # loads the AMD SMBus (i2c-piix4) path

  # GPU pour node_exporter (gpu.prom, à côté de l'extras.prom de
  # modules/node-exporter.nix), lu par anna. Tout vient de sysfs ; une carte
  # suspendue n'est pas lue (une lecture réarme son autosuspend).
  systemd.services.gpu-metrics = {
    description = "GPU AMD pour node_exporter (anna)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${
        lib.getExe (
          pkgs.writeShellApplication {
            name = "gpu-metrics";
            runtimeInputs = [ pkgs.coreutils ];
            text = ''
              # La RX 7600 XT (Navi 33, 0x7480), pas l'iGPU. Une carte endormie n'est pas lue : seul son état l'est.
              dir=$1
              {
                for d in /sys/bus/pci/drivers/amdgpu/0000:*; do
                  [ "$(cat "$d/device" 2>/dev/null)" = 0x7480 ] || continue
                  pci=''${d##*/}
                  state=$(cat "$d/power/runtime_status" 2>/dev/null || echo active)
                  echo "gpu_info{pci=\"$pci\",vendor=\"amd\",name=\"Radeon RX 7600 XT\",state=\"$state\"} 1"
                  echo "gpu_vram_total_bytes{pci=\"$pci\"} $(cat "$d/mem_info_vram_total")"
                  if [ "$state" = active ]; then
                    echo "gpu_busy_percent{pci=\"$pci\"} $(cat "$d/gpu_busy_percent")"
                    echo "gpu_vram_used_bytes{pci=\"$pci\"} $(cat "$d/mem_info_vram_used")"
                    for t in "$d"/hwmon/hwmon*/temp1_input; do
                      echo "gpu_temp_celsius{pci=\"$pci\"} $(($(cat "$t") / 1000))"
                      break
                    done
                  fi
                done
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
