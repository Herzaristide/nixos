{
  pkgs,
  lib,
  ...
}:

# 2-en-1 (exupery) : rotation automatique de l'écran intégré et clavier
# virtuel. Importé par home/home.nix quand `head` et `tablet` sont vrais.
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
  home.packages = [ pkgs.wvkbd ];

  systemd.user.services.hypr-auto-rotate = sessionService "Rotation automatique d'eDP-1" autoRotate;
  systemd.user.services.hypr-osk = sessionService "Clavier virtuel (wvkbd)" osk;

  # Le geste de workspace (3 doigts, horizontal, home/modules/hyprland/hyprland.nix)
  # marche aussi à l'écran tactile, en glissant depuis le bord.
  wayland.windowManager.hyprland.settings.config.gestures.workspace_swipe_touch = true;

  wayland.windowManager.hyprland.extraConfig = ''
    -- Rotation de la tablette (home/modules/tablet.nix), réappliquée à
    -- chaque chargement de la config.
    do
      local f = io.open(${stateFile})
      local t = f and tonumber(f:read("*l"))
      if f then f:close() end
      if t then
        ${rotateLua}
      end
    end
  '';
}
