{
  inputs,
  palette,
  ...
}:

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
      };

      # Mods from https://zen-browser.app/mods
      mods = [
        "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
        "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # No Sidebar Scrollbar
      ];

      # Theme aligned to the NixOS palette (dark background, NixOS blue accent)
      userChrome = ''
        /* ── NixOS palette overrides ────────────────────────── */
        :root {
          --toolbar-bgcolor:                #${palette.base01} !important;
          --toolbar-color:                  #${palette.base05} !important;
          --toolbarbutton-hover-background: rgba(224, 224, 255, 0.08) !important;
          --tab-selected-bgcolor:           #${palette.base02} !important;
          --focus-outline-color:            #${palette.base0D} !important;
          --link-color:                     #${palette.base0D} !important;
          --accent-color:                   #${palette.base0D} !important;
          --accent-color-a30:               rgba(82, 119, 195, 0.3) !important;
        }

        #navigator-toolbox {
          background-color: #${palette.base01} !important;
        }

        #sidebar-box,
        .sidebar-panel,
        #sidebar-header {
          background-color: #${palette.base00} !important;
          color: #${palette.base05} !important;
        }

        /* URL bar */
        #urlbar-background {
          background-color: #${palette.base02} !important;
          border-color: #${palette.base0D} !important;
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
}
