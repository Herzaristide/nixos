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
# Mêmes modules que bernanos (modules/head.nix), sans la NVIDIA ; tout ce
# qui tient à la tablette (rotation, clavier virtuel, tactile, émetteur IR)
# est ici.
let
  inherit (lib.generators) mkLuaInline toLua;

  # L'entrée eDP-1 de modules/monitors.nix, la même que pour la session et le
  # greeter, avec la rotation en plus : `t` est une variable Lua.
  edp = lib.findFirst (m: m.output == "eDP-1") (throw "eDP-1 absent de modules/monitors.nix") (
    import ../../modules/monitors.nix
  );
  rotateLua = ''
    hl.monitor(${toLua { multiline = false; } (edp // { transform = mkLuaInline "t"; })})
    hl.config({ input = { touchdevice = { output = "eDP-1", transform = t } } })
  '';

  # Rotation courante, relue par la config Lua à chaque `hyprctl reload`
  # (que lance anna à chaque changement d'accent) : sans elle, un reload
  # remettrait l'écran à l'endroit quelle que soit la position de la tablette.
  stateFile = ''(os.getenv("XDG_RUNTIME_DIR") or "/nonexistent") .. "/hypr-rotation"'';
  rotateLuaFile = pkgs.writeText "hypr-rotate.lua" rotateLua;

  # `hyprctl keyword monitor …` (iio-hyprland, rot8) ne marche plus avec le
  # parseur Lua : la rotation passe par `hyprctl eval`.
  autoRotate = pkgs.writeShellApplication {
    name = "hypr-auto-rotate";
    runtimeInputs = [
      pkgs.iio-sensor-proxy
      pkgs.hyprland
    ];
    text = ''
      monitor-sensor --accel | while read -r line; do
        case "$line" in
          *orientation*normal*) t=0 ;;
          *orientation*left-up*) t=1 ;;
          *orientation*bottom-up*) t=2 ;;
          *orientation*right-up*) t=3 ;;
          *) continue ;;
        esac
        echo "$t" > "$XDG_RUNTIME_DIR/hypr-rotation"
        hyprctl eval "local t = $t; $(cat ${rotateLuaFile})"
      done
    '';
  };

  # Clavier virtuel : affiché tant qu'aucun clavier USB n'est branché. Le
  # clavier détachable du 7200 est un périphérique USB (connecteur pogo) ;
  # un clavier externe ou le récepteur Logitech comptent aussi, et masquent
  # le clavier virtuel. wvkbd : SIGUSR1 masque, SIGUSR2 affiche.
  osk = pkgs.writeShellApplication {
    name = "hypr-osk";
    runtimeInputs = [
      pkgs.wvkbd
      pkgs.systemd
      pkgs.coreutils
    ];
    text = ''
      wvkbd-mobintl --hidden &
      pid=$!
      trap 'kill "$pid"' EXIT

      has_usb_keyboard() {
        for f in /dev/input/by-path/*-usb-*-event-kbd; do
          [ -e "$f" ] && return 0
        done
        return 1
      }

      update() {
        if has_usb_keyboard; then
          kill -USR1 "$pid"
        else
          kill -USR2 "$pid"
        fi
      }

      sleep 1
      update
      udevadm monitor --udev --subsystem-match=input | while read -r _; do
        update
      done
    '';
  };

  sessionService = description: exec: {
    Unit = {
      Description = description;
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = lib.getExe exec;
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
in
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
    ../../modules/audio.nix
    ../../modules/bluetooth.nix
    ../../modules/security.nix
    ../../modules/impermanence.nix
    ../../modules/print.nix
  ];

  networking.hostName = "exupery";

  primaryMonitor = "eDP-1";

  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # CPU : Intel — KVM + microcode
  boot.kernelModules = [ "kvm-intel" ];
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # Mises à jour BIOS/firmware Dell via LVFS (`fwupdmgr update`).
  services.fwupd.enable = true;

  # --- Énergie (laptop, Intel) ---
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

  # Même correctif que bernanos : powertop met les périphériques USB en
  # autosuspend après 2 s, ce qui fait perdre des frappes au récepteur
  # Logitech et au dongle Corsair. Le clavier détachable du 7200 est lui aussi
  # un périphérique USB (connecteur pogo) : à ajouter ici s'il décroche.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="046d", ATTR{idProduct}=="c548", ATTR{power/autosuspend_delay_ms}="300000"
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="1b1c", ATTR{idProduct}=="1b94", ATTR{power/autosuspend_delay_ms}="300000"
  '';

  # Rabattre le clavier sur l'écran suspend la machine (modules/power.nix
  # ignore le capot par défaut) ; hypridle verrouille avant la veille.
  services.logind.settings.Login.HandleLidSwitch = lib.mkForce "suspend";

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

  # --- Tablette ---
  # Accéléromètre (Intel ISH → hid-sensor) exposé par iio-sensor-proxy, que
  # lit le service de rotation plus bas.
  hardware.sensor.iio.enable = true;

  # Caméra IR pour howdy (modules/head.nix). L'émetteur IR des webcams Dell
  # est éteint par défaut sous Linux : à configurer une fois avec
  # `sudo linux-enable-ir-emitter configure`, avant `sudo howdy add`. La caméra
  # IR est en général le troisième nœud, /dev/video2 — à vérifier avec
  # `v4l2-ctl --list-devices`.
  services.linux-enable-ir-emitter = {
    enable = true;
    device = "video2";
  };
  services.howdy.settings.video.device_path = "/dev/video2";

  # Rotation automatique d'eDP-1 et clavier virtuel, dans la session de
  # l'utilisateur (complète home/home.nix, branché par modules/common.nix).
  home-manager.users.aristide = {
    home.packages = [ pkgs.wvkbd ];

    systemd.user.services.hypr-auto-rotate = sessionService "Rotation automatique d'eDP-1" autoRotate;
    systemd.user.services.hypr-osk = sessionService "Clavier virtuel (wvkbd)" osk;

    # Le geste de workspace (3 doigts, horizontal, home/modules/hyprland/hyprland.nix)
    # marche aussi à l'écran tactile, en glissant depuis le bord.
    wayland.windowManager.hyprland.settings.config.gestures.workspace_swipe_touch = true;

    wayland.windowManager.hyprland.extraConfig = ''
      -- Rotation de la tablette (hosts/exupery/configuration.nix),
      -- réappliquée à chaque chargement de la config.
      do
        local f = io.open(${stateFile})
        local t = f and tonumber(f:read("*l"))
        if f then f:close() end
        if t then
          ${rotateLua}
        end
      end
    '';
  };
}
