{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

# Dell Latitude 7200 2-en-1 : tablette à clavier détachable.
# Intel Core i5-8365U (Whiskey Lake, 4c/8t), Intel UHD 620, 16 Go,
# écran tactile 12,3" 1920×1280, accéléromètre (Intel Sensor Hub), webcam IR.
# Même pile graphique que zola, sans la NVIDIA : un seul GPU, l'iGPU Intel.
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
    ../../modules/nautilus.nix
    ../../modules/greetd.nix
    ../../modules/audio.nix
    ../../modules/bluetooth.nix
    ../../modules/security.nix
    ../../modules/impermanence.nix
    ../../modules/print.nix
  ];

  networking.hostName = "exupery";

  head = true;
  tablet = true;
  primaryMonitor = "eDP-1";

  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # CPU : Intel — KVM + microcode
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Mises à jour BIOS/firmware Dell via LVFS (`fwupdmgr update`).
  services.fwupd.enable = true;

  # --- Énergie (laptop, Intel) — mêmes réglages que zola ---
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.auto-cpufreq = {
    enable = true;
    settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
        scaling_min_freq = 400000; # 400 MHz, plancher du i5-8365U
        scaling_max_freq = 1600000; # fréquence de base
        enable_thresholds = true;
      };
      charger = {
        governor = "performance";
        turbo = "auto";
        scaling_min_freq = 800000;
        scaling_max_freq = 4100000; # turbo max du i5-8365U
      };
    };
  };
  services.thermald.enable = true;
  powerManagement = {
    enable = true;
    cpuFreqGovernor = lib.mkDefault "powersave";
    powertop.enable = true;
  };

  # Même correctif que zola : powertop met les périphériques USB en
  # autosuspend après 2 s, ce qui fait perdre des frappes au récepteur
  # Logitech et au dongle Corsair. Le clavier détachable du 7200 est lui aussi
  # un périphérique USB (connecteur pogo) : à ajouter ici s'il décroche.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c548", ATTR{power/autosuspend_delay_ms}="300000"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1b1c", ATTR{idProduct}=="1b94", ATTR{power/autosuspend_delay_ms}="300000"
  '';

  # --- GPU : Intel UHD 620 seul ---
  environment.variables.LIBVA_DRIVER_NAME = "iHD";
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # VA-API (Gen9.5, iHD)
      vpl-gpu-rt
      libva
    ];
  };
  environment.systemPackages = with pkgs; [
    vulkan-tools
    mesa-demos
    libva-utils
  ];

  # Un seul build à la fois : 4 cœurs / 16 Go, et une machine qu'on tient
  # en main — pas de quoi compiler deux grosses dérivations en parallèle.
  nix.settings.max-jobs = lib.mkForce 1;

  # --- 2-en-1 ---
  # Accéléromètre (Intel ISH → hid-sensor) exposé par iio-sensor-proxy, que
  # lit le service de rotation de home/modules/tablet.nix.
  hardware.sensor.iio.enable = true;

  # --- Reconnaissance faciale (webcam IR) ---
  # L'émetteur IR des webcams Dell est éteint par défaut sous Linux : à
  # configurer une fois avec `sudo linux-enable-ir-emitter configure`, puis
  # enregistrer son visage avec `sudo howdy add`. Les deux stockent leur état
  # sous /var/lib et /etc (racine non effacée par l'impermanence).
  #
  # `device` / `device_path` : la caméra IR, à vérifier sur la machine avec
  # `v4l2-ctl --list-devices` (la caméra RGB et l'IR exposent chacune deux
  # nœuds /dev/videoN ; l'IR est en général le troisième, /dev/video2).
  services.linux-enable-ir-emitter = {
    enable = true;
    device = "video2";
  };
  services.howdy = {
    enable = true;
    # « sufficient » : le visage suffit, le mot de passe reste possible en
    # repli. Le défaut « required » en ferait un second facteur obligatoire.
    control = "sufficient";
    settings.video.device_path = "/dev/video2";
  };
  # howdy se trompe avec une bonne photo : il ne déverrouille que l'écran de
  # verrouillage (Quickshell) et les invites polkit. Ni greetd/login — le mot
  # de passe y déverrouille aussi GNOME Keyring (pam_gnome_keyring), qu'un
  # login par visage laisserait verrouillé —, ni sudo, qui reste au mot de passe.
  security.pam.howdy.enable = false;
  security.pam.services.quickshell.howdy.enable = true;
  security.pam.services.polkit-1.howdy.enable = true;
}
