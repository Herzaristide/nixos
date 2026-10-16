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
    # Syntaxe Lua obligatoire : avec le parseur Lua, `hyprctl dispatch <nom> <args>`
    # est refusé (« dispatch in lua is a shorthand for hl.dispatch(...) ») et
    # `hyprctl keyword` ne fonctionne plus du tout — d'où `hyprctl eval` pour la
    # reconfiguration du moniteur.
    for i in 1 2 3 4 5; do
      hyprctl dispatch "hl.dsp.workspace.move({ workspace = \"$i\", monitor = \"HDMI-A-1\" })"
    done
    hyprctl eval 'hl.monitor({ output = "eDP-1", disabled = true })'
    hyprctl dispatch 'hl.dsp.focus({ monitor = "HDMI-A-1" })'
  '';

  wallpaper = ../../../src/cheng-feng-psdV2Rl-GvU-unsplash.jpg;

  # L'image est étendue sur les deux écrans du bureau, empilés verticalement
  # (cf. modules/monitors.nix) : HP 1600×900 logiques en 0x0, Samsung 1536×864
  # en 0x900, soit une boîte de 1600×1764. On la remplit à l'échelle 1,6 (la
  # définition native du HP) puis on y découpe le rectangle de chaque écran.
  # À recalculer si la disposition change dans monitors.nix.
  wallpaperSplit = pkgs.runCommand "wallpaper-split" { nativeBuildInputs = [ pkgs.imagemagick ]; } ''
    mkdir -p $out
    magick ${wallpaper} -resize 2560x2822^ -gravity center -extent 2560x2822 box.png
    magick box.png -crop 2560x1440+0+0 +repage $out/hp.png
    magick box.png -crop 2458x1382+0+1440 +repage $out/samsung.png
  '';

  # Les connecteurs diffèrent entre gary et zola : on reconnaît les écrans du
  # bureau par leur description EDID ; tout autre écran reçoit l'image entière.
  setWallpaper = pkgs.writeShellApplication {
    name = "set-wallpaper";
    runtimeInputs = [
      pkgs.awww
      pkgs.jq
    ];
    text = ''
      until awww query >/dev/null 2>&1; do sleep 0.1; done
      hyprctl monitors -j | jq -r '.[] | "\(.name)\t\(.description)"' |
        while IFS=$'\t' read -r name desc; do
          case "$desc" in
          "HP Inc. HP E24q G5 CNC3021TQS"*) img=${wallpaperSplit}/hp.png ;;
          "Samsung Electric Company C27R50x H9JTB00510"*) img=${wallpaperSplit}/samsung.png ;;
          *) img=${wallpaper} ;;
          esac
          awww img -o "$name" "$img" --transition-type=fade --transition-duration 0.3 --transition-fps 255
        done
    '';
  };

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
          active_opacity = 0.90;
          inactive_opacity = 0.80;
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
          # Le HP, par description : DP-4 sur gary, DP-3 sur zola.
          monitor = "desc:HP Inc. HP E24q G5 CNC3021TQS";
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
          on_created_empty = "claude-desktop";
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

      -- Karenine : la barre de conversation (panels/ConversationBar.qml) pose
      -- ses réponses sur un voile qui s'efface vers ses bords. Flou derrière
      -- tout pixel un peu opaque : le voile, la pastille, jamais le vide autour.
      -- Même verre pour le texte des sessions (panels/AiDock.qml).
      hl.layer_rule({
        match = { namespace = "^(quickshell-conversation|quickshell-aidock)$" },
        blur = true,
        ignore_alpha = 0.08,
      })

      -- Accent color fragment rewritten by anna on every change.
      -- Loaded at top-level so it applies on every config reload (hyprctl reload)
      -- AND at startup. The fragment returns a table of colors.
      -- Live updates during the session are applied by the anna daemon running
      -- `hyprctl reload` (karenine anna/src/appctl.rs::reload_hyprland) — et non
      -- `hyprctl keyword`, qui ne fonctionne plus avec le parseur Lua.
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
        hl.exec_cmd("${lib.getExe setWallpaper}")
      end)
    '';
  };
}
