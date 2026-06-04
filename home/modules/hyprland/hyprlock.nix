{ ... }:

{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        hide_cursor = true;
        grace = 2;
        no_fade_in = false;
        disable_loading_bar = true;
      };

      background = [
        {
          color = "rgba(20, 20, 30, 1.0)";
          blur_passes = 0;
        }
      ];

      label = [
        {
          text = "cmd[update:1000] date +'%H:%M'";
          color = "rgba(220, 220, 220, 1.0)";
          font_size = 90;
          font_family = "JetBrains Mono";
          position = "0, 160";
          halign = "center";
          valign = "center";
        }
        {
          text = "Bonjour, aristide.";
          color = "rgba(180, 180, 180, 1.0)";
          font_size = 18;
          font_family = "JetBrains Mono";
          position = "0, 60";
          halign = "center";
          valign = "center";
        }
      ];

      input-field = [
        {
          size = "320, 50";
          position = "0, -80";
          halign = "center";
          valign = "center";
          outline_thickness = 2;
          dots_size = 0.25;
          dots_spacing = 0.4;
          fade_on_empty = false;
          placeholder_text = "Mot de passe…";
          hide_input = false;
          check_color = "rgba(82, 119, 195, 1.0)";
          fail_color = "rgba(204, 51, 51, 1.0)";
          fail_text = "Mauvais mot de passe";
        }
      ];
    };
  };

  # hypridle: lock after 30 min idle, DPMS off shortly after, lock before suspend.
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock";
        before_sleep_cmd = "loginctl lock-session";
        after_sleep_cmd = "hyprctl dispatch dpms on";
      };

      listener = [
        {
          timeout = 1800;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 1860;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
      ];
    };
  };
}
