{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Wrapper qui préserve le pinning GPU (AQ_DRM_DEVICES, cf. modules/common.nix
  # `renderDevice`) auparavant fait dans programs.fish.loginShellInit avant
  # l'exec direct de Hyprland à l'autologin. `start-hyprland` (pas `Hyprland`)
  # est le wrapper fourni par le paquet nixpkgs : il importe les variables
  # d'environnement dans systemd/dbus (nécessaire aux portails XDG).
  hyprlandSessionScript = pkgs.writeShellScriptBin "quickshell-hyprland-session" ''
    ${lib.optionalString (config.renderDevice != null) ''
      if [ -e "${config.renderDevice}" ]; then
        export AQ_DRM_DEVICES="$(${pkgs.coreutils}/bin/readlink -f ${config.renderDevice})"
      fi
    ''}
    exec ${config.programs.hyprland.package}/bin/start-hyprland
  '';

  # Session déclarée explicitement (plutôt que de dépendre du .desktop
  # auto-généré par programs.hyprland, dont on ne maîtrise pas l'Exec=)
  # pour garantir que le pinning GPU ci-dessus est bien appliqué.
  hyprlandSessionEntry =
    pkgs.writeTextFile {
      name = "quickshell-hyprland-session";
      destination = "/share/wayland-sessions/hyprland.desktop";
      text = ''
        [Desktop Entry]
        Name=Hyprland
        Comment=Hyprland compositor (Quickshell)
        Exec=${hyprlandSessionScript}/bin/quickshell-hyprland-session
        Type=Application
        DesktopNames=Hyprland
      '';
    }
    // {
      # Requis par services.displayManager.sessionPackages : doit lister le(s)
      # nom(s) de base des .desktop fournis (cf. nixos/modules/services/display-managers/default.nix).
      providedSessions = [ "hyprland" ];
    };

  # Même description des moniteurs que la session utilisateur, rendue en appels
  # `hl.monitor{}` : le greeter est en config Lua comme la session (cf.
  # greeterHyprlandLua plus bas pour la raison).
  monitorLua =
    m:
    "hl.monitor({ output = ${builtins.toJSON m.output}, mode = ${builtins.toJSON m.mode}, "
    + "position = ${builtins.toJSON m.position}, scale = ${toString m.scale}"
    + lib.optionalString (m ? transform) ", transform = ${toString m.transform}"
    + " })";

  wallpaperPng = ../src/nix-wallpaper-binary-black_2k.png;

  # Le fond d'écran est dessiné par le compositeur, et surtout PAS par regreet :
  # son option `background.path` passe le fichier à `gtk::MediaFile` (backend
  # GStreamer) avec `set_loop(true)` + `play()` (src/gui/component.rs). Une image
  # fixe « jouée en boucle » atteint sa fin à chaque frame et repart aussitôt :
  # la boucle GTK est affamée et le greeter cesse de répondre en quelques
  # secondes (c'est ce qui déclenchait l'ANR d'Hyprland).
  hyprpaperConf = pkgs.writeText "greetd-hyprpaper.conf" ''
    preload = ${wallpaperPng}
    wallpaper = ,${wallpaperPng}
    splash = false
    ipc = off
  '';

  # Config Lua, et non hyprlang (`.conf`) : depuis 0.55 hyprlang est déprécié, et
  # 0.56 affiche à l'écran « You are using the .conf config format, support for
  # which will be removed in Hyprland 0.57. » — sur le greeter, donc en travers de
  # l'écran de login. Hyprland choisit son parseur sur l'extension du fichier
  # (src/config/ConfigManager.cpp) : le nom en `.lua` est ce qui bascule sur le
  # gestionnaire Lua, il n'y a pas d'option pour le forcer.
  greeterHyprlandLua = pkgs.writeText "greetd-hyprland.lua" ''
    ${lib.concatMapStringsSep "\n" monitorLua (import ./monitors.nix)}

    hl.config({
      input = {
        kb_layout = "fr",
      },

      animations = {
        enabled = false,
      },

      misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        force_default_wallpaper = 0,
        -- La config est dans le store, immuable : le watcher de rechargement n'a
        -- rien à surveiller et on lui retire toute occasion de recharger la config
        -- sous le nez du greeter.
        disable_autoreload = true,

        -- Sans ça, le greeter est inutilisable : regreet bloque sa boucle GTK le
        -- temps des échanges PAM avec greetd (plusieurs secondes), rate les pings
        -- d'Hyprland, et l'ANR ouvre `hyprland-dialog` — une fenêtre qui prend le
        -- focus clavier, donc plus moyen de taper son mot de passe. Le dialogue
        -- « Terminer / Attendre » n'a de toute façon aucun sens sur un écran de
        -- login : un seul client, et personne pour lui répondre. cage n'avait pas
        -- cette détection, d'où la régression au passage à Hyprland.
        enable_anr_dialog = false,
      },

      debug = {
        -- Hyprland coupe ses propres logs par défaut, et son log fichier vit dans
        -- $XDG_RUNTIME_DIR/hypr/ (donc /run/user/999, en 0700, illisible et effacé
        -- avec la session). On réactive les logs et on les bascule sur stdout, que
        -- le script du greeter redirige vers /var/log/greeter/hyprland.log.
        disable_logs = false,
        enable_stdout_logs = true,
      },
    })

    -- Remplace `exec-once` : en mode Lua l'autostart passe par l'événement
    -- `hyprland.start` (même mécanique que la session, cf. home/modules/hyprland).
    hl.on("hyprland.start", function()
      hl.exec_cmd("${lib.getExe pkgs.hyprpaper} -c ${hyprpaperConf}")

      -- regreet rend la main quand la session est choisie ; on ferme alors le
      -- compositeur pour que greetd enchaîne sur la session utilisateur.
      -- `hyprctl dispatch exit` (forme hyprlang) est rejeté par le parseur Lua :
      -- dispatch y est un raccourci pour hl.dispatch(...), il faut le dispatcher.
      hl.exec_cmd("${lib.getExe config.services.displayManager.regreet.package}; ${config.programs.hyprland.package}/bin/hyprctl dispatch 'hl.dsp.exit()'")
    end)
  '';

  # Le greeter doit être épinglé sur le même GPU que la session : sur gary les
  # écrans sont câblés sur l'iGPU, et sans ce pinning aquamarine choisirait le
  # dGPU, où les sorties portent d'autres noms (DP-2/DP-1) — les lignes monitor
  # ci-dessus, dont la rotation de DP-4, ne matcheraient plus.
  greeterSession = pkgs.writeShellScriptBin "greetd-hyprland-session" ''
    ${lib.optionalString (config.renderDevice != null) ''
      if [ -e "${config.renderDevice}" ]; then
        export AQ_DRM_DEVICES="$(${pkgs.coreutils}/bin/readlink -f ${config.renderDevice})"
      fi
    ''}
    # `start-hyprland` et non `Hyprland` : c'est le lanceur supporté (watchdog +
    # import de l'environnement dans systemd/dbus), comme pour la session
    # utilisateur ci-dessus. Lancer `Hyprland` directement affichait la bannière
    # « Hyprland was started without start-hyprland » (src/i18n/Engine.cpp) sur
    # l'écran de login. Tout ce qui suit `--` est passé à Hyprland.
    exec ${config.programs.hyprland.package}/bin/start-hyprland -- --config ${greeterHyprlandLua} \
      > /var/log/greeter/hyprland.log 2>&1
  '';
in
{
  services.displayManager.sessionPackages = [ hyprlandSessionEntry ];

  # Destination des logs du compositeur du greeter : lisible sans privilèges
  # (contrairement à /run/user/999) et persistant d'un boot à l'autre, sinon un
  # écran de login cassé n'est diagnosticable que depuis un TTY en root.
  systemd.tmpfiles.rules = [
    "d /var/log/greeter 0755 greeter greeter -"
  ];

  # Le compositeur du greeter est Hyprland et non cage : cage n'expose aucun
  # réglage de sortie (pas de rotation, pas de position — cf. `cage -h`), donc
  # l'écran retourné de gary (DP-4, transform 2) s'affichait à l'envers au login.
  # Hyprland relit ici la même liste de moniteurs que la session.
  services.greetd.settings.default_session.command =
    "${pkgs.dbus}/bin/dbus-run-session ${greeterSession}/bin/greetd-hyprland-session";

  # Écran de login (remplace l'autologin) : greetd + regreet.
  # Reskin manuel pour se rapprocher de la palette Quickshell (services/Theme.qml
  # dans le repo karenine) : fond #0d0d0d, accent #5277c3, police JetBrains Mono.
  # Ce n'est pas un rendu QML identique (regreet est du GTK4) — cf. discussion :
  # un greeter Quickshell natif est un développement bien plus lourd, écarté
  # au profit d'un logiciel mature reskinné.
  services.displayManager.regreet = {
    enable = true;

    font = {
      name = "JetBrains Mono";
      size = 12;
      package = pkgs.jetbrains-mono;
    };

    theme.name = "Adwaita";

    settings = {
      GTK.application_prefer_dark_theme = true;
      appearance.greeting_msg = "Bonjour, aristide.";

      # Pas de `background` ici : c'est hyprpaper qui dessine le fond (voir
      # hyprpaperConf plus haut pour la raison — GStreamer).

      # Horloge collée en haut de l'écran (frame #clock_frame).
      widget.clock = {
        format = "%A %d %B — %H:%M";
        resolution = "1s";
        label_width = 300;
      };
    };

    # Les sélecteurs suivent l'arbre de widgets de regreet (src/gui/templates.rs) :
    # un GtkOverlay contenant la GtkPicture de fond, puis trois frames en surimpression
    # portant la classe `background` — la boîte de login (centre), #clock_frame (haut)
    # et la barre reboot/poweroff (bas).
    extraCss = ''
      /* Transparente : le fond d'écran est dessiné par hyprpaper, en dessous. */
      window.background {
        background-color: transparent;
        color: #e0e0ff;
      }

      /* Les frames en surimpression : cartes translucides sur le wallpaper. */
      frame.background {
        background-color: rgba(13, 13, 13, 0.82);
        border: 1px solid #2a2a2a;
        border-radius: 16px;
        box-shadow: 0 8px 32px rgba(0, 0, 0, 0.6);
      }

      #clock_frame {
        padding: 8px 24px;
        font-size: 1.4em;
      }

      #clock_frame label {
        color: #7ebae4;
      }

      label {
        color: #e0e0ff;
      }

      #message_label {
        color: #7ebae4;
      }

      entry,
      passwordentry {
        background-color: #1a1a1a;
        color: #e0e0ff;
        border: 2px solid #2a2a2a;
        border-radius: 8px;
        padding: 6px 10px;
        min-height: 32px;
      }

      entry:focus,
      passwordentry:focus {
        border-color: #5277c3;
      }

      /* Les listes déroulantes utilisateur/session. */
      combobox button {
        background-color: #1a1a1a;
        border-radius: 8px;
      }

      popover contents {
        background-color: #0d0d0d;
        border: 1px solid #2a2a2a;
        border-radius: 8px;
        color: #e0e0ff;
      }

      button {
        background-color: #1a1a1a;
        background-image: none;
        color: #e0e0ff;
        border: 1px solid #2a2a2a;
        border-radius: 8px;
        padding: 4px 14px;
      }

      button:hover {
        background-color: #2a2a2a;
      }

      /* Login */
      button.suggested-action {
        background-color: #5277c3;
        color: #0d0d0d;
        border-color: #5277c3;
        font-weight: bold;
      }

      button.suggested-action:hover {
        background-color: #7ebae4;
      }

      /* Reboot / Power off */
      button.destructive-action {
        background-color: #1a1a1a;
        color: #d4696a;
        border-color: #2a2a2a;
      }

      button.destructive-action:hover {
        background-color: #d4696a;
        color: #0d0d0d;
      }

      button:focus,
      button:focus-visible {
        outline: 2px solid #7ebae4;
        outline-offset: 2px;
      }
    '';
  };
}
