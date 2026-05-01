{
  inputs,
  pkgs,
  lib,
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
        # uBlock Origin : ad/content blocker
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
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
        # Force Zen's own dark mode (0=dark, 1=light, 2=system).
        # This controls color-scheme in zen-browser-container.css and
        # makes light-dark() resolve to the dark variant everywhere.
        "zen.view.window.scheme" = 0;
        # 0 = dark preference for web content (prefers-color-scheme: dark).
        "layout.css.prefers-color-scheme.content-override" = 0;
        "browser.theme.content-theme" = 1;
        "browser.theme.toolbar-theme" = 1;
      };

      # Mods from https://zen-browser.app/mods
      mods = [
        "e122b5d9-d385-4bf8-9971-e137809097d0" # No Top Sites
        "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # No Sidebar Scrollbar
      ];

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

  # The live Zen browser uses ~/.zen/<random-id>.Default Profile/ while home-manager
  # writes user.js to ~/.config/zen/default/. This activation script symlinks both
  # into the actual active profile directory. userChrome.css is rendered to
  # ~/.config/accent/zen-userchrome.css by paletted and linked from there.
  home.activation.zenBridgeProfile =
    lib.hm.dag.entryAfter
      [
        "writeBoundary"
        "accentSeed"
      ]
      ''
        _ZEN_DIR="$HOME/.zen"
        _HM_PROFILE="$HOME/.config/zen/default"

        if [ -f "$_ZEN_DIR/profiles.ini" ]; then
          _ZEN_PROFILE_PATH=$(${pkgs.gnugrep}/bin/grep -oP '(?<=Path=).*' "$_ZEN_DIR/profiles.ini" | head -1)
          if [ -n "$_ZEN_PROFILE_PATH" ]; then
            _ZEN_PROFILE="$_ZEN_DIR/$_ZEN_PROFILE_PATH"
            mkdir -p "$_ZEN_PROFILE/chrome"

            # userChrome.css — rendered by paletted on every accent/mode change
            ln -sf "$HOME/.config/accent/zen-userchrome.css" "$_ZEN_PROFILE/chrome/userChrome.css"

            # user.js — toolkit.legacyUserProfileCustomizations.stylesheets + other prefs
            ln -sf "$_HM_PROFILE/user.js" "$_ZEN_PROFILE/user.js"
          fi
        fi
      '';
}
