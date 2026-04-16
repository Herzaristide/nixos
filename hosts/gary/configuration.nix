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
    ../../modules/common.nix
    ../../modules/head.nix
  ];

  # Hostname
  networking.hostName = "gary";

  # Enable GUI (Hyprland/DMS)
  head = true;

  # Bootloader (systemd-boot for UEFI; GRUB disabled)
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Static IP (systemd-networkd; disable NetworkManager for declarative config)
  networking.networkmanager.enable = true;
  networking.useDHCP = false;
  networking.interfaces.wlp39s0 = {
    ipv4.addresses = [
      {
        address = "192.168.1.100";
        prefixLength = 24;
      }
    ];
  };
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [
    "192.168.1.1"
    "8.8.8.8"
  ];

  # SSH - allow password authentication
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Firmware for hardware (network, etc.)
  hardware.enableRedistributableFirmware = true;

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
  ];

  # /opt/rocm symlink — PyTorch/TensorFlow look for ROCm here by default
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  # ROCM_PATH — points ML frameworks to the ROCm installation
  environment.variables.ROCM_PATH = "${pkgs.rocmPackages.clr}";

  # Blacklist NVIDIA drivers (not needed)
  boot.blacklistedKernelModules = [
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
    "nvidia_uvm"
    "nouveau"
  ];

  # HDD mounts (optional - nofail allows boot without these disks)
  fileSystems."/mnt/hdd1" = {
    device = "/dev/disk/by-uuid/516f5bb5-72b9-47da-b6bb-7b193ac1cd86";
    fsType = "ext4";
    options = [ "nofail" ];
  };
  fileSystems."/mnt/hdd2" = {
    device = "/dev/disk/by-uuid/c25498c3-b03c-43cc-8650-f8183873ceec";
    fsType = "ext4";
    options = [ "nofail" ];
  };
  fileSystems."/mnt/hdd3" = {
    device = "/dev/disk/by-uuid/85a42e9c-ace0-4ecc-a04a-e2e722345d5c";
    fsType = "ext4";
    options = [ "nofail" ];
  };
  fileSystems."/mnt/hdd4" = {
    device = "/dev/disk/by-uuid/8f0502de-aeec-497c-a92a-76ce47fd26de";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  # SSD maintenance — periodic TRIM
  services.fstrim.enable = true;

  # Sleep / power management — suspend on idle, wake on keyboard/mouse
  services.logind = {
    settings.Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      IdleAction = "suspend";
      IdleActionSec = "20min";
      HandleSuspendKey = "suspend";
      HandleHibernateKey = "hibernate";
      HandlePowerKey = "poweroff";
    };
  };

  # Nix experimental features
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # K3s - lightweight Kubernetes cluster (single-node server)
  services.k3s = {
    enable = true;
    role = "server";
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;

    # Allow SSH
    allowedTCPPorts = [
      22 # SSH
      80 # HTTP
      6443 # K3s Kubernetes API server
      10250 # K3s Kubelet metrics
    ];

    # K3s additional ports (etcd, Flannel)
    allowedTCPPortRanges = [
      {
        from = 2379;
        to = 2380;
      } # etcd server-client and peer communication
    ];

    allowedUDPPorts = [
      8472 # Flannel VXLAN overlay network
      51820 # Flannel WireGuard (if used)
      51821 # Flannel WireGuard IPv6 (if used)
    ];

    # Allow trusted local network (adjust if needed)
    trustedInterfaces = [ "lo" ]; # Loopback always trusted
  };
}
