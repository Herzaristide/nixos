{
  config,
  pkgs,
  lib,
  ...
}:

{
  wayland.windowManager.hyprland = {
    enable = true;
    extraConfig = ''
      # Qt theming via DMS matugen (qt6ct)
      env = QT_QPA_PLATFORMTHEME,qt6ct
      env = QT_QPA_PLATFORMTHEME_QT6,qt6ct

      # DMS integration
      # layerrule = noanim 1, ^(dms)$
      misc {
        disable_hyprland_logo = true
        disable_splash_rendering = true
      }
      # DMS keybindings (Super+Space launcher, Super+V clipboard, etc.)
      bind = $mod, space, exec, dms ipc call spotlight toggle
      bind = $mod, V, exec, dms ipc call clipboard toggle
      bind = $mod, M, exec, dms ipc call processlist focusOrToggle
      bind = $mod, comma, exec, dms ipc call settings focusOrToggle
      bind = $mod, N, exec, dms ipc call notifications toggle
      bind = $mod, Y, exec, dms ipc call dankdash wallpaper
      bind = $mod, TAB, exec, dms ipc call hypr toggleOverview
      bind = $mod ALT, L, exec, dms ipc call lock lock
      bindel = , XF86AudioRaiseVolume, exec, dms ipc call audio increment 3
      bindel = , XF86AudioLowerVolume, exec, dms ipc call audio decrement 3
      bindl = , XF86AudioMute, exec, dms ipc call audio mute
      bindel = , XF86MonBrightnessUp, exec, dms ipc call brightness increment 5
      bindel = , XF86MonBrightnessDown, exec, dms ipc call brightness decrement 5
      # Replaced by DMS: togglefloating on Shift+V, exit on Shift+M
      bind = $mod, Shift+V, togglefloating
      bind = $mod, Shift+M, exit
      # DMS window rule
      # windowrulev2 = float, class:^(org.quickshell)$
    '';
    settings = {
      "$mod" = "SUPER";

      # French keyboard + mouse sans accélération (plus fluide, 1:1)
      input = {
        kb_layout = "fr";
        kb_variant = "";
        accel_profile = "flat";
        force_no_accel = true;
      };

      cursor = {
        no_hardware_cursors = 1;
      };

      # GPU: moins d'effets pour GT 630 + nouveau (blur/ombres coûtent cher)
      decoration = {
        rounding = 4;
        active_opacity = 0.95;
        inactive_opacity = 0.75;
      };

      # Special workspace apparaît depuis le bas
      animation = [
        "specialWorkspaceIn, 1, 8, default, slidevert bottom"
        "specialWorkspaceOut, 1, 8, default, slidevert bottom"
      ];

      # Monitors: HDMI-A-1 preferred when plugged, eDP-1 fallback when HDMI unplugged
      # Order matters: first = primary. HDMI at 0x0; eDP auto when both connected.
      monitor = [
        "HDMI-A-1,1920x1080@60,0x0,1.33"
        "eDP-1,preferred,auto-left,1.33"
        ",preferred,auto,1.33"
      ];

      # Autostart: DMS starts via systemd (replaces Waybar)
      exec-once = [ ];

      # Workspaces: 1 = HDMI (externe), 2 = preferred/eDP-1. special:gemini = overlay (scratchpad)
      workspace = [
        "1, monitor:HDMI-A-1"
        "2, monitor:preferred"
        "3, monitor:eDP-1"
        "special:gemini, on-created-empty:hypr-gemini-launch, gapsout:80 200 80 200, gapsin:30"
      ];

      # Minimal binds - terminal, apps
      bind = [
        "$mod, Return, exec, ghostty"
        "$mod, C, exec, cursor"
        "$mod, B, exec, bash -c 'google-chrome-stable --user-data-dir=$HOME/.config/google-chrome-$(hostname)'"
        "$mod, L, exec, bandlab-chrome"
        "$mod, E, exec, eraser--chrome"
        "$mod, Q, killactive"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        # Focus prev/next monitor (bracket keys)
        "$mod, bracketleft, focusmonitor, -1"
        "$mod, bracketright, focusmonitor, +1"
        # Workspaces: 0 = left monitor, 1–5 = main (AZERTY: & é " ' ( = 1 2 3 4 5)
        "$mod, 0, workspace, 0"
        "$mod, ampersand, workspace, 1"
        "$mod, eacute, workspace, 2"
        "$mod, quotedbl, workspace, 3"
        "$mod, apostrophe, workspace, 4"
        "$mod, parenleft, workspace, 5"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        # Workspace spécial Gemini (Super+G) – s'affiche en overlay
        "$mod, G, togglespecialworkspace, gemini"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}
