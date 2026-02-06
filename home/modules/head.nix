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

      # Monitors: VGA-1 primary (scale 1.5), HDMI-1 rotated left (transform 3), fallback for laptop/autres
      monitor = [
        "VGA-1,1920x1080@60,0x0,1.5"
        "HDMI-1,1920x1080@74.97,1280x0,1.5,transform,3"
        ",preferred,auto,1.5"
      ];

      # Minimal binds - terminal, apps
      bind = [
        "$mod, Return, exec, ghostty"
        "$mod, C, exec, cursor"
        "$mod, B, exec, google-chrome-stable"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, V, togglefloating"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}

