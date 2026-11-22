{
  config,
  pkgs,
  lib,
  primaryMonitor ? "HDMI-A-1",
  anna ? null,
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

  shortcuts = import ../shortcuts.nix {
    inherit pkgs;
    lidLayoutPath = toString hyprClosedLidLayout;
  };
in
{
  # Le choix de ce qu'on partage de l'écran (Meet, Discord, OBS) : une carte
  # de karenine, aperçus en direct (anna/src/sharepick.rs), au lieu de
  # hyprland-share-picker, qui reprend la main si karenine ne répond pas.
  xdg.configFile."hypr/xdph.conf" = lib.mkIf (anna != null) {
    text = ''
      screencopy {
          custom_picker_binary = ${anna}/bin/anna-share-picker
      }
    '';
  };

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

        # Les fenêtres sont posées sur la surface de karenine (panels/Surface.qml :
        # la même encre sous les fenêtres, dans la barre du bas et le panneau de
        # droite). Elles suivent sa grille : 18 px au bord de l'écran — là où
        # karenine pose les boutons de la barre (à gauche) et le haut du panneau
        # (SidePanel.qml, `edge`) —, 18 px entre deux fenêtres (2 × gaps_in),
        # et l'arrondi de ses cartes (Theme.radius = 14).
        general = {
          gaps_in = 9;
          gaps_out = 18;
          border_size = 1;
          # Un filet à peine visible sur l'encre, comme les séparateurs de
          # karenine ; gris neutre, lisible en thème sombre comme clair.
          "col.inactive_border" = "rgba(8080802e)";
          # col.active_border is set by the anna fragment
          # (~/.config/accent/fragments/hyprland-colors.lua) loaded below.
        };

        decoration = {
          rounding = 14;
          rounding_power = 2; # un arc de cercle, comme les Rectangle de Qt
          # Une surface plate, sans relief : ni la barre ni le panneau n'ont
          # d'ombre, les fenêtres non plus.
          shadow = {
            enabled = false;
          };
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          # Une application qui demande le focus (xdg-activation) le reçoit :
          # un lien cliqué dans kitty ouvre Chromium/Zed déjà lancé et passe
          # directement sur sa fenêtre (et son workspace) au lieu de la
          # marquer seulement « urgente ».
          focus_on_activate = true;
        };

        # XWayland apps (e.g. Reaper) apparaissent pixelisés avec le fractional scaling
        # (1.25×, 1.60×) car Hyprland upscale la surface X11.  force_zero_scaling=true
        # fait que XWayland expose la résolution physique aux apps → plus de blur.
        # Les apps doivent ensuite gérer leur propre scaling (ex: uiscale dans reaper.ini).
        xwayland = {
          force_zero_scaling = true;
        };
      };

      # Glisser à 3 doigts gauche/droite sur le pavé tactile : workspace
      # voisin sur le même écran. Sur exupery, hosts/exupery/configuration.nix étend
      # le geste à l'écran tactile (gestures.workspace_swipe_touch).
      gesture = [
        {
          fingers = 3;
          direction = "horizontal";
          action = "workspace";
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
          # Le HP, par description : DP-4 sur gary, DP-3 sur bernanos.
          monitor = "desc:HP Inc. HP E24q G5 CNC3021TQS";
          default = true;
        }
      ];

      # Raccourcis définis dans home/modules/shortcuts.nix (source de vérité
      # partagée avec kitty/Zed/micro).
      bind = map (b: {
        _args = [
          b.keys
          (mkLuaInline b.lua)
        ]
        ++ lib.optional (b ? opts) b.opts;
      }) shortcuts.hyprland;

      window_rule = [
        # Nautilus flottant par défaut, taille réduite et centré
        {
          match = {
            class = "^(org.gnome.Nautilus)$";
          };
          float = true;
          size = "1000 650";
          center = true;
        }
        # Les visionneuses (home/modules/viewers.nix, f3d.nix) : de petites
        # fenêtres flottantes et centrées, qu'on ferme une fois regardé.
        # Images : imv.
        {
          match = {
            class = "^(imv)$";
          };
          float = true;
          size = "900 620";
          center = true;
        }
        # Audio : mpv lancé par mpv-audio.desktop (--wayland-app-id).
        {
          match = {
            class = "^(mpv-audio)$";
          };
          float = true;
          size = "560 320";
          center = true;
        }
        # Modèles 3D : f3d. Il passe par XWayland (VTK), dont la fenêtre a
        # pour classe « Vtk » ; son titre, « fichier - F3D » (ou « F3D - A
        # fast and minimalist 3D viewer » sans fichier), en filet de sécurité.
        # Pas de `size` : f3d impose la sienne (--resolution, 1000×600 px
        # physiques, soit 800×480 ici) juste après s'être ouvert. Il est lancé
        # avec --no-cache (f3d.nix), sinon il restaure sa dernière position.
        {
          match = {
            class = "^([Vv]tk|f3d)$";
          };
          float = true;
          center = true;
        }
        {
          match = {
            title = "(^| - )F3D( - .*)?$";
          };
          float = true;
          center = true;
        }
        # Vidéo : mpv (mpv.desktop, app_id « mpv »), plus grand.
        {
          match = {
            class = "^(mpv)$";
          };
          float = true;
          size = "1024 576";
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
        # Recopie d'écran du téléphone (scrcpy) : flottante, à la taille que
        # scrcpy calcule d'après le ratio du téléphone. Le wrapper Nix donne
        # la classe `.scrcpy-wrapped`.
        {
          match = {
            class = "^(\\.?scrcpy(-wrapped)?)$";
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

      -- Karenine : la barre de conversation (panels/ConversationBar.qml) pose
      -- ses réponses sur un voile qui s'efface vers ses bords. Flou derrière
      -- tout pixel un peu opaque : le voile, la pastille, jamais le vide autour.
      hl.layer_rule({
        match = { namespace = "^quickshell-conversation$" },
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
        hl.exec_cmd("kdeconnectd")
        -- L'agent Bluetooth (modules/bluetooth.nix) : appareil connecté,
        -- demandes d'appairage, envoyés au serveur de notifications de karenine.
        -- Hyprland ne lance pas les autostarts XDG, d'où cette ligne.
        hl.exec_cmd("blueman-applet")
      end)
    '';
  };
}
