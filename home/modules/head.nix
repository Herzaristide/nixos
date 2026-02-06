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

      # Monitors: HDMI-1 vertical left, VGA-1 main right (scale 1.6)
      monitor = [
        "HDMI-1,1920x1080@74.97,0x0,1.33,transform,3"
        "VGA-1,1920x1080@60,675x0,1.33"
        ",preferred,auto,1.33"
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
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
  };
}

