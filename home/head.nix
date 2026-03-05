{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./modules/hyprland.nix
    inputs.dms.homeModules.dank-material-shell
    inputs.danksearch.homeModules.dsearch
  ];

  programs.dank-material-shell = {
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
    # Core features
    enableSystemMonitoring = true; # System monitoring widgets (dgop)
    enableVPN = true; # VPN management widget
    enableDynamicTheming = true; # Wallpaper-based theming (matugen)
    enableAudioWavelength = true; # Audio visualizer (cava)
    enableCalendarEvents = true; # Calendar integration (khal)
    enableClipboardPaste = true; # Pasting items from the clipboard (wtype)

    # Full DMS settings from ~/.config/DankMaterialShell/settings.json.bak
    # Override showDock and appLauncherViewMode to match live preferences
    settings = (import ./dms-settings.nix) // { };
  };

  programs.dsearch.enable = true;

  # Mouse cursor theme (Hyprland, GTK apps)
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.phinger-cursors;
    name = "phinger-cursors-dark";
    size = 32;
  };

  programs.vscode = {
    enable = true;
    package = pkgs.code-cursor;
    mutableExtensionsDir = true;
    profiles = {
      default = {
        extensions = with pkgs.vscode-extensions; [
          ms-python.python
          charliermarsh.ruff
          sonarsource.sonarlint-vscode
          dbaeumer.vscode-eslint
          esbenp.prettier-vscode
          mkhl.direnv
          jnoortheen.nix-ide
          arrterian.nix-env-selector
          bradlc.vscode-tailwindcss
          golang.go
          hashicorp.terraform
          rust-lang.rust-analyzer
          ms-azuretools.vscode-containers
          ms-azuretools.vscode-docker
        ];
        userSettings = {
          "[python]" = {
            "editor.defaultFormatter" = "charliermarsh.ruff";
            "editor.formatOnSave" = true;
            "editor.codeActionsOnSave" = {
              "source.fixAll.ruff" = "explicit";
            };
          };
          "[javascript]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
            "editor.formatOnSave" = true;
          };
          "[javascriptreact]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
            "editor.formatOnSave" = true;
          };
          "[typescript]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
            "editor.formatOnSave" = true;
          };
          "[typescriptreact]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
            "editor.formatOnSave" = true;
          };
          "[json]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
            "editor.formatOnSave" = true;
          };
          "[jsonc]" = {
            "editor.defaultFormatter" = "esbenp.prettier-vscode";
            "editor.formatOnSave" = true;
          };
          "[go]" = {
            "editor.defaultFormatter" = "golang.go";
            "editor.formatOnSave" = true;
          };
          "[terraform]" = {
            "editor.defaultFormatter" = "hashicorp.terraform";
            "editor.formatOnSave" = true;
          };
          "[terraform-vars]" = {
            "editor.defaultFormatter" = "hashicorp.terraform";
            "editor.formatOnSave" = true;
          };
          "[rust]" = {
            "editor.defaultFormatter" = "rust-lang.rust-analyzer";
            "editor.formatOnSave" = true;
          };
          "[nix]" = {
            "editor.defaultFormatter" = "jnoortheen.nix-ide";
            "editor.formatOnSave" = true;
          };
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
          "nix.serverSettings" = {
            "nixd" = {
              "formatting" = {
                "command" = [ "${pkgs.nixfmt}/bin/nixfmt" ];
              };
            };
          };
          "sonarlint.pathToNodeExecutable" = "${pkgs.nodejs_22}/bin/node";
          "window.openFoldersInNewWindow" = "on";
          "workbench.activityBar.location" = "top";
        };
      };
    };
  };

  # Headful (GUI) packages for desktop/laptop systems
  # adw-gtk3, qt6ct: required for DMS matugen GTK/Qt application theming
  home.packages = with pkgs; [
    adw-gtk3
    qt6Packages.qt6ct
    dgop
    nautilus
    gnome-online-accounts # Google Drive in Nautilus via Settings > Online Accounts
    gnome-control-center # Add Google account: run "gnome-control-center" → Online Accounts
    code-cursor
    google-chrome
    firefox
    ghostty
    (writeShellScriptBin "hypr-gemini-launch" ''
      google-chrome-stable --app=https://gemini.google.com --user-data-dir="$HOME/.config/google-chrome-$(hostname)" &
      ghostty --class=gemini-term &
    '')
    (writeShellScriptBin "gemini-chrome" ''
      exec google-chrome-stable --app=https://gemini.google.com --user-data-dir="$HOME/.config/google-chrome-$(hostname)"
    '')
    (writeShellScriptBin "bandlab-chrome" ''
      exec google-chrome-stable --app=https://www.bandlab.com --user-data-dir="$HOME/.config/google-chrome-$(hostname)"
    '')
    (writeShellScriptBin "eraser-chrome" ''
      exec google-chrome-stable --app=https://app.eraser.io --user-data-dir="$HOME/.config/google-chrome-$(hostname)"
    '')
  ];

  # Default applications (force overwrites existing mimeapps.list files)
  xdg.configFile."mimeapps.list".force = true;
  xdg.dataFile."applications/mimeapps.list".force = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-terminal-emulator" = [ "ghostty.desktop" ];
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
      "x-scheme-handler/file" = [ "org.gnome.Nautilus.desktop" ];
    };
  };

  # Gemini webapp (Chrome in app mode)
  xdg.desktopEntries.gemini = {
    name = "Gemini";
    comment = "Google Gemini AI";
    exec = "gemini-chrome";
    icon = "google-chrome";
    categories = [
      "Network"
      "Chat"
    ];
    startupNotify = true;
  };

  # BandLab PWA (Chrome in app mode)
  xdg.desktopEntries.bandlab = {
    name = "BandLab";
    comment = "Music Maker & Audio Editor";
    exec = "bandlab-chrome";
    icon = "google-chrome";
    categories = [
      "Audio"
      "Music"
      "Network"
    ];
    startupNotify = true;
  };

  # Online Accounts - add Google Drive for Nautilus (opens GNOME Settings → Online Accounts)
  xdg.desktopEntries.online-accounts = {
    name = "Online Accounts";
    comment = "Add Google Drive and other cloud accounts for Nautilus";
    exec = "gnome-control-center online-accounts";
    icon = "org.gnome.Settings-online-accounts-symbolic";
    categories = [
      "Settings"
      "System"
    ];
    startupNotify = true;
  };

  # Eraser PWA (Chrome in app mode) - diagrams & docs for engineering teams
  xdg.desktopEntries.eraser = {
    name = "Eraser";
    comment = "AI co-pilot for technical design and documentation";
    exec = "eraser-chrome";
    icon = "google-chrome";
    categories = [
      "Development"
      "Graphics"
      "Network"
    ];
    startupNotify = true;
  };

  # Set environment variables for Cursor/VSCode to use Firefox for opening links
  home.sessionVariables = {
    BROWSER = "firefox";
  };
}
