{
  inputs,
  pkgs,
  palettes,
  lib,
  ...
}:

let
  # Convert a 6-char lowercase hex string (no #) to "r,g,b"
  hexToRgb =
    hex:
    let
      d2i =
        d:
        {
          "0" = 0;
          "1" = 1;
          "2" = 2;
          "3" = 3;
          "4" = 4;
          "5" = 5;
          "6" = 6;
          "7" = 7;
          "8" = 8;
          "9" = 9;
          "a" = 10;
          "b" = 11;
          "c" = 12;
          "d" = 13;
          "e" = 14;
          "f" = 15;
        }
        .${d};
      byte =
        s:
        (d2i (builtins.substring 0 1 (lib.toLower s))) * 16
        + (d2i (builtins.substring 1 1 (lib.toLower s)));
    in
    "${toString (byte (builtins.substring 0 2 hex))},${toString (byte (builtins.substring 2 2 hex))},${
      toString (byte (builtins.substring 4 2 hex))
    }";

  # Build the palette CSS variables for one mode
  mkZenCSS = p: ''
    :root {
      --toolbar-bgcolor:                #${p.base01} !important;
      --toolbar-color:                  #${p.base05} !important;
      --toolbarbutton-hover-background: rgba(${hexToRgb p.base05}, 0.08) !important;
      --tab-selected-bgcolor:           #${p.base02} !important;
      --focus-outline-color:            #${p.base0D} !important;
      --link-color:                     #${p.base0D} !important;
      --accent-color:                   #${p.base0D} !important;
      --accent-color-a30:               rgba(${hexToRgb p.base0D}, 0.3) !important;
    }

    #navigator-toolbox {
      background-color: #${p.base01} !important;
    }

    #sidebar-box,
    .sidebar-panel,
    #sidebar-header {
      background-color: #${p.base00} !important;
      color: #${p.base05} !important;
    }

    #urlbar-background {
      background-color: #${p.base02} !important;
      border-color: #${p.base0D} !important;
    }
  '';
in
{
  imports = [ inputs.zen-browser.homeModules.twilight ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "zen-twilight.desktop";
      "x-scheme-handler/http" = "zen-twilight.desktop";
      "x-scheme-handler/https" = "zen-twilight.desktop";
      "x-scheme-handler/about" = "zen-twilight.desktop";
      "x-scheme-handler/unknown" = "zen-twilight.desktop";
    };
  };

  programs.zen-browser = {
    enable = true;

    policies = {
      DisableAppUpdate = true;
      DisableTelemetry = true;
      DisablePocket = true;

      # Extensions installées automatiquement (force_installed = non-désinstallable)
      ExtensionSettings = {
        # Vimium-FF : navigation clavier complète (hjkl, f pour follow-links, /search…)
        "{dc8b3ea7-735f-4f1e-a512-7e40a8ccad87}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
          installation_mode = "force_installed";
        };
        # React DevTools : debug des composants React
        "{60f82f00-9ad5-4de5-b31c-b16a47c51558}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/react-devtools/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };

    profiles.default = {
      settings = {
        "zen.welcome-screen.seen" = true;
        "zen.urlbar.behavior" = "float";
        "zen.workspaces.continue-where-left-off" = true;
        "zen.view.compact.toolbar-flash-popup" = false;
        # Required for userChrome.css to be loaded
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };

      # Mods from https://zen-browser.app/mods
      mods = [
        "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
        "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # No Sidebar Scrollbar
      ];

      # Both palette modes embedded at build time. Zen switches instantly when the
      # Quickshell toggle fires gsettings color-scheme, because Firefox/Zen honours
      # prefers-color-scheme from the system setting — no rebuild required.
      userChrome = ''
        /* ── NixOS palette — dark/light via prefers-color-scheme ───────── */

        @media (prefers-color-scheme: dark) {
          ${mkZenCSS palettes.dark}
        }

        @media (prefers-color-scheme: light) {
          ${mkZenCSS palettes.light}
        }
      '';

      # ⚠ Ferme Zen avant d'exécuter nixos-rebuild quand keyboardShortcuts est déclaré.
      # Pour trouver les IDs : jq -c '.shortcuts[] | {id, key}' ~/.config/zen/default/zen-keyboard-shortcuts.json | fzf
      # Pour la version   : about:config → zen.keyboard.shortcuts.version
      keyboardShortcutsVersion = 17;
      keyboardShortcuts = [
        # Compact mode (masque la barre d'onglets)
        {
          id = "zen-compact-mode-toggle";
          key = "c";
          modifiers = {
            control = true;
            alt = true;
          };
        }
        # Toggle sidebar
        {
          id = "zen-toggle-sidebar";
          key = "x";
          modifiers = {
            control = true;
            alt = true;
          };
        }
        # Désactive le raccourci Ctrl+Q (quitter accidentellement)
        {
          id = "key_quitApplication";
          disabled = true;
        }
        # Nouvel onglet
        {
          id = "key_newNavigatorTab";
          key = "t";
          modifiers.control = true;
        }
      ];
    };
  };

  # The home-manager zen-browser module writes its profile to ~/.config/zen/default/
  # but the live Zen browser uses ~/.zen/<random-id>.Default Profile/ (its own data dir).
  # This activation script reads ~/.zen/profiles.ini at rebuild time and symlinks
  # the generated userChrome.css and user.js into the actual active profile directory.
  home.activation.zenBridgeProfile = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _ZEN_DIR="$HOME/.zen"
    _HM_PROFILE="$HOME/.config/zen/default"

    if [ -f "$_ZEN_DIR/profiles.ini" ]; then
      _ZEN_PROFILE_PATH=$(${pkgs.gnugrep}/bin/grep -oP '(?<=Path=).*' "$_ZEN_DIR/profiles.ini" | head -1)
      if [ -n "$_ZEN_PROFILE_PATH" ]; then
        _ZEN_PROFILE="$_ZEN_DIR/$_ZEN_PROFILE_PATH"
        mkdir -p "$_ZEN_PROFILE/chrome"

        # userChrome.css — palette colors
        ln -sf "$_HM_PROFILE/chrome/userChrome.css" "$_ZEN_PROFILE/chrome/userChrome.css"

        # user.js — toolkit.legacyUserProfileCustomizations.stylesheets + other prefs
        ln -sf "$_HM_PROFILE/user.js" "$_ZEN_PROFILE/user.js"
      fi
    fi
  '';
}
