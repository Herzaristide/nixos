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

  # Clavier virtuel : squeekboard, qui parle input-method-v2 et ne s'affiche
  # que lorsqu'une application active un champ de saisie (text-input-v3 :
  # GTK, Qt, Alacritty ; Chromium avec les flags plus bas). wvkbd, l'ancien
  # clavier, n'a aucune notion de champ de saisie : il était affiché ou non,
  # point. squeekboard a en plus une disposition AZERTY (input-sources).
  #
  # Le paquet nixpkgs ne compile plus avec le Rust actuel : `close` y est
  # déclaré sans valeur de retour, ce que rustc refuse désormais
  # (invalid_runtime_symbol_definitions). À retirer quand nixpkgs aura corrigé.
  squeekboard = pkgs.squeekboard.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace src/vkeyboard.rs \
        --replace-fail "fn close(fd: i32);" "fn close(fd: i32) -> i32;"
    '';
  });

  # Gestes tactiles. Le hyprgrass de nixpkgs ne compile pas (wf-touch y a
  # avancé au-delà de ce qu'il attend) et vise de toute façon Hyprland 0.55 :
  # ici le commit qu'hyprpm.toml (amont) associe à Hyprland 0.56.2, avec le
  # wf-touch épinglé par ce même commit. À réaligner à chaque montée
  # d'Hyprland — un plugin compilé contre une autre version refuse de charger.
  hyprgrass =
    let
      src = pkgs.fetchFromGitHub {
        owner = "horriblename";
        repo = "hyprgrass";
        rev = "8e605468cbf429791d61ddbfaeb14ff5e08fec3e"; # Hyprland v0.56.2
        hash = "sha256-0nXTqzvZQSoTbpKcDmc4kciHmlIXfMZfLk5E1Ax9CP0=";
      };
    in
    (pkgs.hyprlandPlugins.hyprgrass.override {
      wf-touch = pkgs.callPackage "${src}/nix/wf-touch.nix" { };
    }).overrideAttrs
      {
        inherit src;
        version = "0.8.2-unstable-2026-08-11";
      };

  # Claviers physiques qui ne doivent pas masquer le clavier virtuel : des
  # souris qui exposent aussi une interface clavier (touches de macro), par
  # leur nom udev. `journalctl --user -u hypr-osk` liste les claviers vus.
  ignoredKeyboards = [ ];

  # squeekboard lit `screen-keyboard-enabled` comme « aucun clavier
  # physique » (server-context-service.c) : à false, il ne s'affiche jamais,
  # même dans un champ de saisie. Ce service la tient à jour : false dès qu'un
  # clavier USB (le clavier détachable du 7200, connecteur pogo, en est un) ou
  # Bluetooth est présent. Les claviers internes (boutons de la tablette,
  # « Intel HID events », i8042) sont sur d'autres bus et ne comptent pas.
  osk = pkgs.writeShellApplication {
    name = "hypr-osk";
    runtimeInputs = [
      squeekboard
      pkgs.systemd
      pkgs.dconf
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      ignored=(${lib.escapeShellArgs ignoredKeyboards})

      # Un clavier physique : ID_INPUT_KEYBOARD (touches alphabétiques) sur
      # le bus USB (0003) ou Bluetooth (0005).
      keyboards() {
        local ev dev name bus i
        for ev in /sys/class/input/event*; do
          dev=$ev/device
          [ -r "$dev/id/bustype" ] || continue
          bus=$(cat "$dev/id/bustype")
          [ "$bus" = 0003 ] || [ "$bus" = 0005 ] || continue
          udevadm info --query=property --path="$ev" 2>/dev/null \
            | grep -qx 'ID_INPUT_KEYBOARD=1' || continue
          name=$(cat "$dev/name")
          for i in "''${ignored[@]}"; do
            [ "$name" = "$i" ] && continue 2
          done
          echo "$name"
        done
      }

      last=
      update() {
        local found state
        found=$(keyboards | sort -u)
        if [ -n "$found" ]; then state=false; else state=true; fi
        [ "$state" = "$last" ] && return
        last=$state
        dconf write /org/gnome/desktop/a11y/applications/screen-keyboard-enabled "$state"
        if [ -n "$found" ]; then
          echo "clavier virtuel désactivé, claviers : $(paste -sd ',' <<< "$found")"
        else
          echo "clavier virtuel activé (aucun clavier physique)"
        fi
      }

      update
      squeekboard &
      pid=$!
      trap 'kill "$pid" 2>/dev/null' EXIT

      # Branchement/débranchement USB, connexion/déconnexion Bluetooth (uhid).
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
  home-manager.users.aristide = { lib, ... }: {
    systemd.user.services.hypr-auto-rotate = sessionService "Rotation automatique d'eDP-1" autoRotate;
    systemd.user.services.hypr-osk = sessionService "Clavier virtuel (squeekboard)" osk;

    # Disposition du clavier virtuel (squeekboard la lit ici, pas dans Hyprland).
    dconf.settings."org/gnome/desktop/input-sources".sources = [
      (lib.hm.gvariant.mkTuple [
        "xkb"
        "fr"
      ])
    ];

    # Chromium et les PWA n'envoient leurs champs de saisie à l'input method
    # (donc au clavier virtuel) qu'avec l'IME Wayland activé.
    programs.chromium.commandLineArgs = [
      "--enable-wayland-ime"
      "--wayland-text-input-version=3"
    ];

    # Le geste de workspace (3 doigts, horizontal, home/modules/hyprland/hyprland.nix)
    # marche aussi à l'écran tactile, en glissant depuis le bord.
    wayland.windowManager.hyprland.settings.config.gestures.workspace_swipe_touch = true;

    # Gestes tactiles (hyprgrass), chargés avant le reste de la config Lua
    # par home-manager (hl.plugin.load).
    wayland.windowManager.hyprland.plugins = [ hyprgrass ];
    wayland.windowManager.hyprland.settings.config.plugin.hyprgrass = {
      # La valeur par défaut (1.0) est trop faible sur un écran de tablette,
      # selon la doc amont.
      sensitivity = 4.0;
      long_press_delay = 400;
      # Appui long sur une bordure ou un espace entre fenêtres : redimensionner.
      resize_on_border_long_press = true;
      edge_margin = 10;
    };

    wayland.windowManager.hyprland.extraConfig = ''
      -- Gestes tactiles (hyprgrass) : appui long à 3 doigts pour déplacer la
      -- fenêtre, glisser à 3 doigts vers le bas pour la fermer (Super+Q).
      hl.plugin.hyprgrass.bind({
        pattern = { kind = "longpress", fingers = 3 },
        action = hl.dsp.window.drag(),
        mouse = true,
      })
      hl.plugin.hyprgrass.gesture({
        pattern = { kind = "swipe", fingers = 3, direction = "down" },
        action = "close",
      })

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
