{ config, pkgs, ... }:

{
  # Headful (GUI) packages for desktop/laptop systems
  home.packages = with pkgs; [
    code-cursor
    google-chrome
    ghostty
  ];

  # Hyprland
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";

      # French keyboard
      input = {
        kb_layout = "fr";
        kb_variant = "";
      };

      cursor = {
        no_hardware_cursors = 1;
      };

      # Monitors: HDMI-A-1 left, VGA-1 right, centrés sur l'axe Y.
      # HDMI: 2560x1440 portrait, scale 1.60 → 900×1600 logical. VGA: 1920x1080, scale 1.33 → 1444×812 logical.
      # Centrage Y: HDMI centre 800, VGA y = 800 - 406 = 394
      monitor = [
        "HDMI-A-1,2560x1440@74.97,0x0,1.60,transform,1"
        "VGA-1,1920x1080@60,900x394,1.33"
        ",preferred,auto,1"
      ];

      # Workspaces: 1–3 on VGA (main), 4 on HDMI (single, no switching)
      workspace = [
        "1, monitor:VGA-1, default:true"
        "2, monitor:VGA-1"
        "3, monitor:VGA-1"
        "4, monitor:HDMI-A-1"
      ];

      # Minimal binds - terminal, apps
      bind = [
        "$mod, Return, exec, ghostty"
        "$mod, C, exec, cursor"
        "$mod, B, exec, bash -c 'google-chrome-stable --user-data-dir=$HOME/.config/google-chrome-$(hostname)'"
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
        # Workspaces 1–3 on VGA (AZERTY: & é " sans shift, ou 1 2 3 avec shift)
        "$mod, ampersand, workspace, 1"
        "$mod, eacute, workspace, 2"
        "$mod, quotedbl, workspace, 3"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}

