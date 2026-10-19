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

  # Fond d'écran animé : les vidéos déposées dans ~/d3pot/vid/fonds, jouées en
  # boucle par mpvpaper, la même sur chaque écran (`ALL`), recadrée pour le
  # remplir (`panscan=1.0`). Décodage matériel VA-API (Radeon sur gary, iGPU
  # Intel sur zola via LIBVA_DRIVER_NAME=iHD). `--auto-pause` suspend la lecture
  # quand le fond est entièrement masqué.
  #
  # mpvpaper n'ouvre qu'un seul mpv pour tous les écrans : `wallpaper set`
  # change donc de vidéo à chaud par son socket IPC (`loadfile … replace`),
  # sans relancer le lecteur ni repasser par un fond noir. C'est la commande
  # qu'appelle la source « fonds » de karenine (services/WallpaperSource.qml).
  # Le choix survit au reboot dans ~/.local/state/wallpaper (persisté dans
  # modules/impermanence.nix).
  #
  # La vidéo choisie est aussi recopiée dans /var/lib/wallpaper/current
  # (dossier créé par modules/greetd.nix) : c'est là que la lisent le greeter,
  # qui n'a pas accès à ~, et le lockscreen. Copie par reflink : /var et /home
  # sont sur le même btrfs, elle ne coûte presque rien.
  wallpaper = pkgs.writeShellApplication {
    name = "wallpaper";
    runtimeInputs = with pkgs; [
      mpvpaper
      socat
      jq
      coreutils
      findutils
    ];
    text = ''
      dir="$HOME/d3pot/vid/fonds"
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/wallpaper/current"
      sock="''${XDG_RUNTIME_DIR:-/tmp}/mpvpaper.sock"
      shared=/var/lib/wallpaper

      list() {
        [ -d "$dir" ] || return 0
        find -L "$dir" -maxdepth 1 -type f \
          \( -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' \
             -o -iname '*.mov' -o -iname '*.gif' \) | sort
      }

      # Le choix enregistré s'il existe encore, sinon la première vidéo.
      current() {
        if [ -f "$state" ] && [ -f "$(cat "$state")" ]; then
          cat "$state"
        else
          list | head -n 1
        fi
      }

      ipc() {
        socat - "UNIX-CONNECT:$sock" >/dev/null 2>&1
      }

      # Recopie la vidéo dans le dossier partagé, sauf si c'est déjà elle.
      # Écrite à côté puis renommée : un lecteur qui l'ouvre à ce moment voit
      # l'ancienne ou la nouvelle, jamais une copie à moitié faite. Sans le
      # dossier (hôte sans greeter), on ne fait rien.
      share() {
        [ -d "$shared" ] && [ -w "$shared" ] || return 0
        [ "$(cat "$shared/source" 2>/dev/null)" = "$1" ] && [ -f "$shared/current" ] && return 0
        cp --reflink=auto -- "$1" "$shared/.current.tmp" &&
          chmod 0644 "$shared/.current.tmp" &&
          mv -f -- "$shared/.current.tmp" "$shared/current" &&
          printf '%s\n' "$1" >"$shared/source"
      }

      start() {
        video=$(current)
        if [ -z "$video" ]; then
          echo "wallpaper: aucune vidéo dans $dir" >&2
          exit 1
        fi
        share "$video" &
        exec mpvpaper --auto-pause \
          -o "no-audio loop hwdec=auto-safe panscan=1.0 input-ipc-server=$sock" \
          ALL "$video"
      }

      case "''${1:-start}" in
      start) start ;;
      # Une ligne par vidéo : « * » devant celle qui joue, un espace sinon.
      list)
        cur=$(current)
        list | while IFS= read -r f; do
          if [ "$f" = "$cur" ]; then printf '*\t%s\n' "$f"; else printf ' \t%s\n' "$f"; fi
        done
        ;;
      current) current ;;
      set)
        video=$(realpath -- "''${2:?usage: wallpaper set <vidéo>}")
        [ -f "$video" ] || { echo "wallpaper: $video introuvable" >&2; exit 1; }
        mkdir -p "$(dirname "$state")"
        printf '%s\n' "$video" >"$state"
        share "$video" || echo "wallpaper: copie vers $shared impossible" >&2
        # Lecteur absent (tué, ou dossier vide au démarrage) : on le lance.
        jq -cn --arg f "$video" '{command: ["loadfile", $f, "replace"]}' | ipc ||
          setsid -f "$0" start >/dev/null 2>&1
        ;;
      *)
        echo "usage: wallpaper [start|list|current|set <vidéo>]" >&2
        exit 2
        ;;
      esac
    '';
  };

  shortcuts = import ../shortcuts.nix {
    inherit pkgs;
    lidLayoutPath = toString hyprClosedLidLayout;
  };
in
{
  # Sur le PATH : karenine appelle `wallpaper list` / `wallpaper set`.
  home.packages = [ wallpaper ];

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
        hl.exec_cmd("kdeconnectd")
        -- L'agent Bluetooth (modules/bluetooth.nix) : appareil connecté,
        -- demandes d'appairage, envoyés au serveur de notifications de karenine.
        -- Hyprland ne lance pas les autostarts XDG, d'où cette ligne.
        hl.exec_cmd("blueman-applet")
        hl.exec_cmd("${lib.getExe wallpaper}")
      end)
    '';
  };
}
