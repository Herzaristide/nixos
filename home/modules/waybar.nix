{ config, pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        spacing = 4;

        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "network" "tray" ];

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          format-icons = {
            default = " ";
            active = " ";
          };
        };

        "hyprland/window" = {
          format = "{}";
          max-length = 50;
        };

        clock = {
          format = "{:%H:%M  %d/%m}";
          tooltip-format = "<big>{:%A %d %B %Y}</big>\n<tt>{calendar}</tt>";
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "  muted";
          format-icons = {
            default = [ " " " " " " ];
          };
          on-click = "pactl set-sink-mute @DEFAULT_SINK@ toggle";
          tooltip-format = "{volume}% volume";
        };

        network = {
          format-wifi = " {signalStrength}%";
          format-ethernet = " ";
          format-disconnected = " disconnected";
          tooltip-format = "{ifname}: {ipaddr}/{cidr}";
        };

        tray = {
          icon-size = 16;
          spacing = 8;
        };
      };
    };
    style = ''
      * {
        border: none;
        border-radius: 0;
        min-height: 0;
        font-family: sans-serif;
        font-size: 13px;
      }
      window#waybar {
        background: transparent;
      }
      #workspaces button {
        padding: 0 8px;
        color: inherit;
      }
      #workspaces button.active {
        background: rgba(255, 255, 255, 0.15);
      }
      #clock, #pulseaudio, #network, #tray {
        padding: 0 10px;
      }
    '';
  };
}
