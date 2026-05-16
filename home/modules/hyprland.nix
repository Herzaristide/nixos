{
  config,
  pkgs,
  lib,
  primaryMonitor ? "HDMI-A-1",
  ...
}:

let
  inherit (lib.generators) mkLuaInline;

  hyprClosedLidLayout = pkgs.writeShellScript "hypr-closed-lid-layout" ''
    skip_lid_check=false
    [ "''${1:-}" = --force ] && skip_lid_check=true

    if [ "$skip_lid_check" != true ]; then
      lid_closed=false
      for f in /proc/acpi/button/lid/*/state; do
        [ -r "$f" ] || continue
        if grep -qi closed "$f"; then
          lid_closed=true
          break
        fi
      done
      [ "$lid_closed" = true ] || exit 0
    fi

    if ! hyprctl monitors -j 2>/dev/null | grep -q HDMI-A-1; then
      exit 0
    fi
    for i in 1 2 3 4 5; do
      hyprctl dispatch moveworkspacetomonitor "$i" HDMI-A-1
    done
    hyprctl keyword monitor "eDP-1,disable"
    hyprctl dispatch focusmonitor HDMI-A-1
  '';

  wallpaperPng = ../../src/nix-wallpaper-binary-black_2k.png;
in
{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    settings = {
      env = [
        {
          _args = [
            "FC_FONTATIONS"
            "0"
          ];
        }
        {
          _args = [
            "GTK_THEME"
            "Breeze-Dark"
          ];
        }
        {
          _args = [
            "QT_QPA_PLATFORMTHEME"
            "kde"
          ];
        }
        {
          _args = [
            "KDE_SESSION_VERSION"
            "6"
          ];
        }
      ];

      config = {
        input = {
          kb_layout = "fr";
          kb_variant = "";
          accel_profile = "flat";
          force_no_accel = true;
        };

        cursor = {
          no_hardware_cursors = 1;
        };

        general = {
          gaps_in = 8;
          gaps_out = 12;
          "col.inactive_border" = "rgba(44444433)";
          # col.active_border is set by the paletted fragment
          # (~/.config/accent/fragments/hyprland-colors.lua) loaded below.
        };

        decoration = {
          rounding = 2;
          active_opacity = 0.75;
          inactive_opacity = 0.60;
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };
      };

      animation = [
        {
          leaf = "specialWorkspaceIn";
          enabled = true;
          speed = 8;
          bezier = "default";
          style = "slidevert bottom";
        }
        {
          leaf = "specialWorkspaceOut";
          enabled = true;
          speed = 8;
          bezier = "default";
          style = "slidevert bottom";
        }
      ];

      monitor = [
        {
          output = "DP-3";
          mode = "2560x1440@75";
          position = "0x0";
          scale = 1.60;
          transform = 2;
        }
        {
          output = "HDMI-A-1";
          mode = "1920x1080@60";
          position = "49x900";
          scale = 1.25;
        }
        {
          output = "eDP-1";
          mode = "preferred";
          position = "auto-left";
          scale = 1.25;
        }
        {
          output = "";
          mode = "preferred";
          position = "auto";
          scale = 1.25;
        }
      ];

      # Runs on every config load (le script Lua entier est ré-exécuté à chaque reload).
      exec_cmd = [ "${hyprClosedLidLayout}" ];

      workspace_rule = [
        {
          workspace = "1";
          monitor = primaryMonitor;
          default = true;
        }
        {
          workspace = "2";
          monitor = primaryMonitor;
        }
        {
          workspace = "3";
          monitor = primaryMonitor;
        }
        {
          workspace = "4";
          monitor = primaryMonitor;
        }
        {
          workspace = "5";
          monitor = primaryMonitor;
        }
        {
          workspace = "9";
          monitor = "DP-3";
          default = true;
        }
        # gaps_out: css_gap = soit un int soit { top, right, bottom, left }.
        # En hyprlang `gapsout:60 300 60` = top=60, h=300, bottom=60 (CSS 3-valeurs).
        {
          workspace = "special:claude";
          on_created_empty = "hypr-claude-launch";
          gaps_out = {
            top = 60;
            right = 300;
            bottom = 60;
            left = 300;
          };
        }
        {
          workspace = "special:gemini";
          on_created_empty = "hypr-gemini-launch";
          gaps_out = {
            top = 60;
            right = 300;
            bottom = 60;
            left = 300;
          };
        }
      ];

      bind = [
        # Apps
        {
          _args = [
            "SUPER + Return"
            (mkLuaInline ''hl.dsp.exec_cmd("alacritty")'')
          ];
        }
        {
          _args = [
            "SUPER + V"
            (mkLuaInline ''hl.dsp.exec_cmd("code")'')
          ];
        }
        {
          _args = [
            "SUPER + F"
            (mkLuaInline ''hl.dsp.exec_cmd("file-explorer")'')
          ];
        }
        {
          _args = [
            "SUPER + D"
            (mkLuaInline ''hl.dsp.exec_cmd("vesktop")'')
          ];
        }
        {
          _args = [
            "SUPER + Z"
            (mkLuaInline ''hl.dsp.exec_cmd("zen-twilight")'')
          ];
        }
        {
          _args = [
            "SUPER + R"
            (mkLuaInline ''hl.dsp.exec_cmd("walker")'')
          ];
        }
        {
          _args = [
            "SUPER + CTRL + space"
            (mkLuaInline ''hl.dsp.exec_cmd("walker")'')
          ];
        }
        {
          _args = [
            "SUPER + SHIFT + R"
            (mkLuaInline ''hl.dsp.exec_cmd("pkill quickshell; quickshell &")'')
          ];
        }

        # Window management
        {
          _args = [
            "SUPER + Q"
            (mkLuaInline "hl.dsp.window.close()")
          ];
        }
        {
          _args = [
            "SUPER + T"
            (mkLuaInline ''hl.dsp.window.float({ action = "toggle" })'')
          ];
        }
        {
          _args = [
            "SUPER + SHIFT + V"
            (mkLuaInline ''hl.dsp.window.float({ action = "toggle" })'')
          ];
        }
        {
          _args = [
            "SUPER + P"
            (mkLuaInline "hl.dsp.window.pseudo()")
          ];
        }
        {
          _args = [
            "SUPER + J"
            (mkLuaInline ''hl.dsp.layout("togglesplit")'')
          ];
        }
        # TODO: hl.dsp.exit() peut ne pas exister directement — fallback hyprctl si besoin.
        {
          _args = [
            "SUPER + SHIFT + M"
            (mkLuaInline ''hl.dsp.exec_cmd("hyprctl dispatch exit")'')
          ];
        }

        # Focus
        {
          _args = [
            "SUPER + left"
            (mkLuaInline ''hl.dsp.focus({ direction = "left" })'')
          ];
        }
        {
          _args = [
            "SUPER + right"
            (mkLuaInline ''hl.dsp.focus({ direction = "right" })'')
          ];
        }
        {
          _args = [
            "SUPER + up"
            (mkLuaInline ''hl.dsp.focus({ direction = "up" })'')
          ];
        }
        {
          _args = [
            "SUPER + down"
            (mkLuaInline ''hl.dsp.focus({ direction = "down" })'')
          ];
        }
        # TODO: vérifier l'API monitor focus (peut-être hl.dsp.focus({ monitor = ... })).
        {
          _args = [
            "SUPER + bracketleft"
            (mkLuaInline ''hl.dsp.exec_cmd("hyprctl dispatch focusmonitor -1")'')
          ];
        }
        {
          _args = [
            "SUPER + bracketright"
            (mkLuaInline ''hl.dsp.exec_cmd("hyprctl dispatch focusmonitor +1")'')
          ];
        }

        # Workspaces AZERTY (& é " ' ( pour 1-5, ² pour 9)
        {
          _args = [
            "SUPER + ampersand"
            (mkLuaInline "hl.dsp.focus({ workspace = 1 })")
          ];
        }
        {
          _args = [
            "SUPER + eacute"
            (mkLuaInline "hl.dsp.focus({ workspace = 2 })")
          ];
        }
        {
          _args = [
            "SUPER + quotedbl"
            (mkLuaInline "hl.dsp.focus({ workspace = 3 })")
          ];
        }
        {
          _args = [
            "SUPER + apostrophe"
            (mkLuaInline "hl.dsp.focus({ workspace = 4 })")
          ];
        }
        {
          _args = [
            "SUPER + parenleft"
            (mkLuaInline "hl.dsp.focus({ workspace = 5 })")
          ];
        }
        {
          _args = [
            "SUPER + twosuperior"
            (mkLuaInline "hl.dsp.focus({ workspace = 9 })")
          ];
        }

        {
          _args = [
            "SUPER + SHIFT + ampersand"
            (mkLuaInline "hl.dsp.window.move({ workspace = 1 })")
          ];
        }
        {
          _args = [
            "SUPER + SHIFT + eacute"
            (mkLuaInline "hl.dsp.window.move({ workspace = 2 })")
          ];
        }
        {
          _args = [
            "SUPER + SHIFT + quotedbl"
            (mkLuaInline "hl.dsp.window.move({ workspace = 3 })")
          ];
        }
        {
          _args = [
            "SUPER + SHIFT + apostrophe"
            (mkLuaInline "hl.dsp.window.move({ workspace = 4 })")
          ];
        }
        {
          _args = [
            "SUPER + SHIFT + parenleft"
            (mkLuaInline "hl.dsp.window.move({ workspace = 5 })")
          ];
        }
        {
          _args = [
            "SUPER + SHIFT + twosuperior"
            (mkLuaInline "hl.dsp.window.move({ workspace = 9 })")
          ];
        }

        # Special workspaces
        {
          _args = [
            "SUPER + C"
            (mkLuaInline ''hl.dsp.workspace.toggle_special("claude")'')
          ];
        }
        {
          _args = [
            "SUPER + G"
            (mkLuaInline ''hl.dsp.workspace.toggle_special("gemini")'')
          ];
        }

        # Quickshell panel widgets
        {
          _args = [
            "SUPER + F1"
            (mkLuaInline ''hl.dsp.exec_cmd("echo widget:0 > /tmp/qs-panel.fifo")'')
          ];
        }
        {
          _args = [
            "SUPER + F2"
            (mkLuaInline ''hl.dsp.exec_cmd("echo widget:1 > /tmp/qs-panel.fifo")'')
          ];
        }
        {
          _args = [
            "SUPER + F3"
            (mkLuaInline ''hl.dsp.exec_cmd("echo widget:2 > /tmp/qs-panel.fifo")'')
          ];
        }
        {
          _args = [
            "SUPER + F4"
            (mkLuaInline ''hl.dsp.exec_cmd("echo widget:3 > /tmp/qs-panel.fifo")'')
          ];
        }
        {
          _args = [
            "SUPER + F5"
            (mkLuaInline ''hl.dsp.exec_cmd("echo widget:4 > /tmp/qs-panel.fifo")'')
          ];
        }

        # Mouse drag/resize (ex-bindm)
        {
          _args = [
            "SUPER + mouse:272"
            (mkLuaInline "hl.dsp.window.drag()")
            { mouse = true; }
          ];
        }
        {
          _args = [
            "SUPER + mouse:273"
            (mkLuaInline "hl.dsp.window.resize()")
            { mouse = true; }
          ];
        }

        # Volume / brightness (ex-bindel / bindl)
        {
          _args = [
            "XF86AudioRaiseVolume"
            (mkLuaInline ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%+")'')
            {
              locked = true;
              repeating = true;
            }
          ];
        }
        {
          _args = [
            "XF86AudioLowerVolume"
            (mkLuaInline ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 3%-")'')
            {
              locked = true;
              repeating = true;
            }
          ];
        }
        {
          _args = [
            "XF86AudioMute"
            (mkLuaInline ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")'')
            { locked = true; }
          ];
        }
        {
          _args = [
            "XF86MonBrightnessUp"
            (mkLuaInline ''hl.dsp.exec_cmd("brightnessctl set 5%+")'')
            {
              locked = true;
              repeating = true;
            }
          ];
        }
        {
          _args = [
            "XF86MonBrightnessDown"
            (mkLuaInline ''hl.dsp.exec_cmd("brightnessctl set 5%-")'')
            {
              locked = true;
              repeating = true;
            }
          ];
        }

        # Lid switch — en Lua, pas de "mod, key" : juste "switch:on:Lid Switch".
        {
          _args = [
            "switch:on:Lid Switch"
            (mkLuaInline ''hl.dsp.exec_cmd("${hyprClosedLidLayout} --force")'')
            { locked = true; }
          ];
        }
        {
          _args = [
            "switch:off:Lid Switch"
            (mkLuaInline ''hl.dsp.exec_cmd("hyprctl keyword monitor 'eDP-1,preferred,auto-left,1.33'")'')
            { locked = true; }
          ];
        }
      ];

      window_rule = [
        # File-chooser dialogs (titre)
        {
          match = {
            title = "^(Open File)(.*)";
          };
          float = true;
        }
        {
          match = {
            title = "^(Select a File)(.*)";
          };
          float = true;
        }
        {
          match = {
            title = "^(Choose Files)(.*)";
          };
          float = true;
        }
        {
          match = {
            title = "^(Save File)(.*)";
          };
          float = true;
        }
        {
          match = {
            title = "^(Save As)(.*)";
          };
          float = true;
        }
        {
          match = {
            title = "^(Upload)(.*)";
          };
          float = true;
        }
        {
          match = {
            title = "^(.*File Upload.*)";
          };
          float = true;
        }
        {
          match = {
            title = "^(.*)(Open|Save|Select|Choose|Upload|Download)(.*)";
          };
          float = true;
        }

        # XDG portal
        {
          match = {
            class = "^(xdg-desktop-portal-gtk)$";
          };
          float = true;
        }
        {
          match = {
            class = "^(xdg-desktop-portal)$";
          };
          float = true;
        }
        {
          match = {
            class = "^(org.freedesktop.impl.portal.desktop.gtk)$";
          };
          float = true;
        }

        # Custom file-explorer (Iced) — règles consolidées
        {
          match = {
            class = "^(file-explorer)$";
          };
          float = true;
          size = "900 600";
          center = 1;
        }
        {
          match = {
            class = "^(file_explorer)$";
          };
          float = true;
          size = "900 600";
          center = 1;
        }
        {
          match = {
            title = "^(File Explorer)(.*)$";
          };
          float = true;
          size = "900 600";
          center = 1;
        }

        # VSCode opacity — l'API Lua attend un string format hyprlang "active inactive".
        {
          match = {
            class = "^(code-url-handler|code|Code)$";
          };
          opacity = "0.92 0.82";
        }

        # Misc dialogs
        {
          match = {
            class = "^(file_progress)$";
          };
          float = true;
        }
        {
          match = {
            class = "^(confirm)$";
          };
          float = true;
        }
        {
          match = {
            class = "^(dialog)$";
          };
          float = true;
        }
        {
          match = {
            class = "^(download)$";
          };
          float = true;
        }
        {
          match = {
            class = "^(notification)$";
          };
          float = true;
        }
        {
          match = {
            class = "^(error)$";
          };
          float = true;
        }
        {
          match = {
            class = "^(splash)$";
          };
          float = true;
        }
        {
          match = {
            class = "^(toolbar)$";
          };
          float = true;
        }
      ];
    };

    # extraConfig est désormais du Lua brut (configType = "lua").
    extraConfig = ''
      -- Accent color fragment rewritten by paletted on every change.
      -- Loaded at top-level so it applies on every config reload (hyprctl reload)
      -- AND at startup. The fragment returns a table of colors.
      -- Live updates during the session are pushed directly by the paletted daemon
      -- via `hyprctl keyword` (see accent-daemon/src/appctl.rs::reload_hyprland).
      do
        local ok, colors = pcall(dofile, os.getenv("HOME") .. "/.config/accent/fragments/hyprland-colors.lua")
        if ok and type(colors) == "table" and colors.accent_rgba then
          hl.config({ general = { col = { active_border = colors.accent_rgba } } })
        end
      end

      -- Autostart au démarrage de Hyprland (remplace exec-once).
      hl.on("hyprland.start", function()
        hl.exec_cmd("gsettings set org.gnome.desktop.interface gtk-theme Breeze-Dark")
        hl.exec_cmd("gsettings set org.gnome.desktop.interface color-scheme prefer-dark")
        hl.exec_cmd("${hyprClosedLidLayout}")
        hl.exec_cmd("quickshell")
        hl.exec_cmd("walker --gapplication-service")
        hl.exec_cmd("awww-daemon")
        hl.exec_cmd("sh -c 'until [ -S /run/user/$(id -u)/wayland-1-awww-daemon.sock ]; do sleep 0.1; done; awww img ${wallpaperPng} --transition-type=fade --transition-duration 0.3 --transition-fps 255'")
      end)
    '';
  };
}
