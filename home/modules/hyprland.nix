{ config, pkgs, lib, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
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
        active_opacity = 0.90;
        inactive_opacity = 0.80;
      };

      # Special workspace apparaît depuis le bas
      animation = [
        "specialWorkspaceIn, 1, 8, default, slidevert bottom"
        "specialWorkspaceOut, 1, 8, default, slidevert bottom"
      ];

      # Monitors: HDMI-A-1 left (portrait), VGA-1 right, côte à côte sans gap
      # HDMI: 1920x1080 portrait, scale 1.33 → logical 812×1444
      # VGA: 1920x1080, scale 1.33 → logical 1444×812. Pos x=812 (à droite de HDMI), y centré: 722-406=316
      monitor = [
        "HDMI-A-1,1920x1080@60,0x0,1.33,transform,1"
        "VGA-1,1920x1080@60,812x316,1.33"
        ",preferred,auto,1"
      ];

      # Autostart: waybar, Cursor with one project per workspace (see cursorWorkspaceProjects), Chrome on ws 4
      exec-once = [
        "waybar"
      ];

      # Workspaces: 1–3 on VGA (main), 4 on HDMI. special:gemini = overlay (scratchpad)
      # Lock apps to workspaces (syntax moderne); Cursor per project by title (basename)
      workspace = [
        "4, monitor:HDMI-A-1"
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
        "$mod, M, exit"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        # Focus prev/next monitor (bracket keys)
        "$mod, bracketleft, focusmonitor, -1"
        "$mod, bracketright, focusmonitor, +1"
        # Workspaces (AZERTY: & é " = 1 2 3)
        "$mod, ampersand, workspace, 1"
        "$mod, eacute, workspace, 2"
        "$mod, quotedbl, workspace, 3"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
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
