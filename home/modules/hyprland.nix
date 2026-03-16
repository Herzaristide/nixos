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
      # Dark mode + theming for all apps
      env = GTK_THEME,adw-gtk3-dark
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

      # Autostart: Dark mode for portal/Chromium, then bar and wallpaper
      exec-once = [
        "gsettings set org.gnome.desktop.interface gtk-theme adw-gtk3-dark"
        "gsettings set org.gnome.desktop.interface color-scheme prefer-dark"

        # Quickshell bar (local declarative kurukurubar - bottom-positioned)
        "quickshell"

        # Waybar (uncomment if using Waybar instead of kurukurubar)
        # "waybar"

        # Hyprpaper (uncomment if using hyprpaper instead of swww)
        "hyprpaper"
      ];

      # Workspaces: avoid persistent monitor binding (Hyprland has bugs with workspace-to-monitor).
      # Use default:true so new windows go to ws 1; switch with Super+1..9 (AZERTY &é"'(-è_ç).
      workspace = [
        "1, default:true"
        "special:claude, on-created-empty:hypr-claude-launch, gapsout:80 200 80 200, gapsin:30"
      ];

      # Minimal binds - terminal, apps
      bind = [
        "$mod, Return, exec, wezterm"
        "$mod SHIFT, Return, exec, ghostty" # Ghostty terminal
        "$mod, A, exec, claude-desktop"
        "$mod, C, exec, cursor"
        "$mod, E, exec, code"
        "$mod, B, exec, chromium"
        "$mod, D, exec, discord"
        "$mod, F, exec, figma-linux"
        "$mod, R, exec, pkill rofi || rofi -show drun" # App launcher (Super+R)
        "$mod, Q, killactive"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"

        # Rofi launcher
        "$mod CTRL, space, exec, pkill rofi || rofi -show drun" # Rofi launcher (Ctrl+Super+Space)
        "$mod SHIFT, R, exec, pkill quickshell; quickshell &" # Reload Quickshell bar
        # "$mod SHIFT, R, exec, pkill waybar; waybar &" # Reload Waybar (alternative)
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        # Focus prev/next monitor (bracket keys)
        "$mod, bracketleft, focusmonitor, -1"
        "$mod, bracketright, focusmonitor, +1"
        # Workspaces: 1–9 (AZERTY: & é " ' ( - è _ ç = 1 2 3 4 5 6 7 8 9)
        "$mod, ampersand, workspace, 1"
        "$mod, eacute, workspace, 2"
        "$mod, quotedbl, workspace, 3"
        "$mod, apostrophe, workspace, 4"
        "$mod, parenleft, workspace, 5"
        "$mod, minus, workspace, 6"
        "$mod, egrave, workspace, 7"
        "$mod, underscore, workspace, 8"
        "$mod, ccedilla, workspace, 9"

        # Move window to workspace 1-9
        "$mod SHIFT, ampersand, movetoworkspace, 1"
        "$mod SHIFT, eacute, movetoworkspace, 2"
        "$mod SHIFT, quotedbl, movetoworkspace, 3"
        "$mod SHIFT, apostrophe, movetoworkspace, 4"
        "$mod SHIFT, parenleft, movetoworkspace, 5"
        "$mod SHIFT, minus, movetoworkspace, 6"
        "$mod SHIFT, egrave, movetoworkspace, 7"
        "$mod SHIFT, underscore, movetoworkspace, 8"
        "$mod SHIFT, ccedilla, movetoworkspace, 9"

        # Workspace spécial Claude (Super+G) – s'affiche en overlay
        "$mod, G, togglespecialworkspace, claude"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      # Lid switch: when lid closes, move workspaces to HDMI then disable eDP (avoids workspaces stuck on disabled monitor).
      # Only disable eDP if HDMI-A-1 is present, so laptop-only use is unchanged.
      bindl = [
        ", switch:on:Lid Switch, exec, sh -c 'if hyprctl monitors -j | grep -q HDMI-A-1; then for i in 1 2 3 4 5 6 7 8 9; do hyprctl dispatch moveworkspacetomonitor \\$i HDMI-A-1; done; hyprctl keyword monitor \"eDP-1,disable\"; hyprctl dispatch focusmonitor HDMI-A-1; fi'"
        ", switch:off:Lid Switch, exec, hyprctl keyword monitor 'eDP-1,preferred,auto-left,1.33'"
      ];
    };
  };
}
