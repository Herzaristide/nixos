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

      # Palette alignée sur services/Theme.qml (karenine) : bgDeep #0d0d0d,
      # textPrimary #e0e0ff, textSecondary #8a90b0, accent #5277c3 (défaut
      # NixOS blue du moteur anna), colorDanger #cc4444.
      background = [
        {
          color = "rgba(13, 13, 13, 1.0)";
          blur_passes = 0;
        }
      ];

      label = [
        {
          text = "cmd[update:1000] date +'%H:%M'";
          color = "rgba(224, 224, 255, 1.0)";
          font_size = 90;
          font_family = "JetBrains Mono";
          position = "0, 160";
          halign = "center";
          valign = "center";
        }
        {
          text = "Bonjour, aristide.";
          color = "rgba(138, 144, 176, 1.0)";
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
          inner_color = "rgba(26, 26, 26, 1.0)";
          font_color = "rgba(224, 224, 255, 1.0)";
          check_color = "rgba(82, 119, 195, 1.0)";
          fail_color = "rgba(204, 68, 68, 1.0)";
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
