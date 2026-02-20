{ config, pkgs, lib, ... }:

let
  c = config.lib.stylix.colors;
in
{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "bottom";
        height = 32;
        spacing = 6;
        margin-top = 0;
        margin-bottom = 6;
        margin-left = 8;
        margin-right = 8;

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
    # Appended after Stylix's palette-based CSS (uses @base00–base0F)
    style = lib.mkAfter ''
      window#waybar {
        border-radius: 10px 10px 0 0;
        background-color: ${c.withHashtag.base01};
        border: 1px solid ${c.withHashtag.base02};
        border-bottom: none;
      }
      tooltip {
        border-radius: 8px;
        border: 1px solid ${c.withHashtag.base02};
      }
      #workspaces button {
        padding: 0 10px;
        border-radius: 6px;
        margin: 2px 1px;
      }
      #workspaces button.active {
        background-color: ${c.withHashtag.base02};
      }
      #clock, #pulseaudio, #network, #tray {
        padding: 0 12px;
        margin: 2px 0;
      }
      #window {
        margin-left: 8px;
      }
    '';
  };
}
