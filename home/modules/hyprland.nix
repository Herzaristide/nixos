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
      bind = $mod SHIFT, V, togglefloating
      bind = $mod SHIFT, M, exit
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
        rounding = 2;
        active_opacity = 0.85;
        inactive_opacity = 0.60;
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

      # Autostart: Quickshell bar at bottom, then switch to workspace 1
      exec-once = [
        "qs -p ${config.xdg.configHome}/quickshell/bar.qml"
        "swww-daemon"
        "swww img /etc/nixos/src/wallpaper.jpg --transition-type=fade"
      ];

      # Workspaces: 1–5 on same screen (HDMI when plugged, eDP fallback when not)
      workspace = [
        #"1, monitor:preferred"
        #"2, monitor:preferred"
        #"3, monitor:preferred"
        #"4, monitor:preferred"
        #"5, monitor:preferred"
        "special:claude, on-created-empty:hypr-claude-launch, gapsout:80 200 80 200, gapsin:30"
      ];

      # Minimal binds - terminal, apps
      bind = [
        "$mod, Return, exec, wezterm"
        "$mod, C, exec, cursor"
        "$mod, B, exec, bash -c 'google-chrome-stable --user-data-dir=$HOME/.config/google-chrome-$(hostname)'"
        "$mod, D, exec, discord"
        "$mod, F, exec, figma-linux"
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
        "$mod, ampersand, workspace, 1"
        "$mod, eacute, workspace, 2"
        "$mod, quotedbl, workspace, 3"
        "$mod, apostrophe, workspace, 4"
        "$mod, parenleft, workspace, 5"

        # Workspace spécial Claude (Super+G) – s'affiche en overlay
        "$mod, G, togglespecialworkspace, claude"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Lid switch handling: disable laptop display when lid closed, switch focus to HDMI
      # Move workspaces 1–5 to HDMI first (otherwise they stay on disabled eDP and become unreachable)
      # Note: This uses the switch: syntax which requires Hyprland 0.45+
      bindl = [
        ", switch:on:Lid Switch, exec, sh -c 'for i in 1 2 3 4 5; do hyprctl dispatch moveworkspacetomonitor \$i HDMI-A-1; done; hyprctl keyword monitor \"eDP-1,disable\"; hyprctl dispatch focusmonitor HDMI-A-1'"
        ", switch:off:Lid Switch, exec, hyprctl keyword monitor 'eDP-1,preferred,auto-left,1.33'"
      ];
    };
  };
}
