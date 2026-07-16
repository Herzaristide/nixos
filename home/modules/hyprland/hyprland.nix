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

  wallpaperPng = ../../../src/nix-wallpaper-binary-black_2k.png;

  shortcuts = import ../shortcuts.nix {
    inherit pkgs;
    lidLayoutPath = toString hyprClosedLidLayout;
  };
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
        # Qt apps en Wayland natif (fix pixellisation sur moniteurs scale != 1.0).
        # Fallback xcb si l'app n'a pas le plugin Wayland.
        {
          _args = [
            "QT_QPA_PLATFORM"
            "wayland;xcb"
          ];
        }
        {
          _args = [
            "QT_ENABLE_HIGHDPI_SCALING"
            "1"
          ];
        }
        # Set explicitly (rather than relying on the login shell's exported
        # session variables) so the cursor theme is always applied even if
        # Hyprland is (re)started with a stale shell environment — e.g. right
        # after `nixos-rebuild switch` but before a fresh login.
        {
          _args = [
            "XCURSOR_THEME"
            config.home.pointerCursor.name
          ];
        }
        {
          _args = [
            "XCURSOR_SIZE"
            (toString config.home.pointerCursor.size)
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
          # col.active_border is set by the anna fragment
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

        # XWayland apps (e.g. Reaper) apparaissent pixelisés avec le fractional scaling
        # (1.25×, 1.60×) car Hyprland upscale la surface X11.  force_zero_scaling=true
        # fait que XWayland expose la résolution physique aux apps → plus de blur.
        # Les apps doivent ensuite gérer leur propre scaling (ex: uiscale dans reaper.ini).
        xwayland = {
          force_zero_scaling = true;
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

      # Liste partagée avec le greeter (cf. modules/monitors.nix).
      monitor = import ../../../modules/monitors.nix;

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
          monitor = "DP-4";
          default = true;
        }
        # gaps_out: css_gap = soit un int soit { top, right, bottom, left }.
        # En hyprlang `gapsout:60 300 60` = top=60, h=300, bottom=60 (CSS 3-valeurs).
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
        {
          workspace = "special:claude";
          on_created_empty = "claude-pwa";
          gaps_out = {
            top = 60;
            right = 300;
            bottom = 60;
            left = 300;
          };
        }
      ];

      # Raccourcis définis dans home/modules/shortcuts.nix (source de vérité
      # partagée avec Alacritty/zellij/Zed/micro).
      bind = map (b: {
        _args = [
          b.keys
          (mkLuaInline b.lua)
        ]
        ++ lib.optional (b ? opts) b.opts;
      }) shortcuts.hyprland;

      window_rule = [
        # Dolphin flottant par défaut, taille réduite et centré
        {
          match = {
            class = "^(org.kde.dolphin)$";
          };
          float = true;
          size = "1000 650";
          center = true;
        }
        # Émulateur Android : flottant et centré — sinon la fenêtre s'ouvre
        # hors écran (position X négative, au-delà des moniteurs).
        {
          match = {
            class = "^(Emulator)$";
          };
          float = true;
          center = true;
        }
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

        # Minecraft : opacité pleine. `override` est obligatoire — sans lui,
        # la valeur est multipliée par decoration.active_opacity (0.75) → reste transparent.
        {
          match = {
            class = "^(Minecraft).*";
          };
          opacity = "1.0 override 1.0 override";
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

      -- Tofi : flou + assombrissement de l'écran sauf la zone du launcher.
      -- Le namespace du layer-surface de tofi est "launcher" (vérifié via hyprctl layers).
      -- API : HL.LayerRuleSpec attend `match = { namespace = ... }` + booléens (cf. stubs/hl.meta.lua).
      hl.layer_rule({
        match = { namespace = "^(launcher)$" },
        dim_around = true,
      })

      -- Accent color fragment rewritten by anna on every change.
      -- Loaded at top-level so it applies on every config reload (hyprctl reload)
      -- AND at startup. The fragment returns a table of colors.
      -- Live updates during the session are pushed directly by the anna daemon
      -- via `hyprctl keyword` (see karenine anna/src/appctl.rs::reload_hyprland).
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
        hl.exec_cmd("awww-daemon")
        hl.exec_cmd("sh -c 'until [ -S /run/user/$(id -u)/wayland-1-awww-daemon.sock ]; do sleep 0.1; done; awww img ${wallpaperPng} --transition-type=fade --transition-duration 0.3 --transition-fps 255'")
      end)
    '';
  };
}
