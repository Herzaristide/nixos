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
    ./modules/vscode/vscode.nix
    ./modules/wezterm.nix
    ./modules/quickshell/quickshell.nix
    ./modules/walker.nix
  ];

  # Mouse cursor theme (Hyprland, GTK apps)
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.phinger-cursors;
    name = "phinger-cursors-dark";
    size = 32;
  };

  # dconf: required for GTK portal dialogs (file picker, commit popup) to pick up font settings.
  # GTK settings.ini alone is not enough — portal-spawned dialogs read from GSettings (dconf).
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface" = {
        font-name = "DejaVu Sans 11";
        document-font-name = "DejaVu Sans 11";
        monospace-font-name = "DejaVu Sans Mono 11";
        color-scheme = "prefer-dark";
        gtk-theme = "adw-gtk3-dark";
      };
    };
  };

  # Dark mode system-wide (GTK, GNOME apps, XDG portal, Chromium)
  gtk = {
    enable = true;
    font = {
      name = "DejaVu Sans";
      size = 11;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = true;
    };
    gtk4 = {
      theme = null;
      extraConfig = {
        "gtk-application-prefer-dark-theme" = true;
      };
    };
  };

  # Qt: follow GTK theme + font (fixes broken fonts in Qt file dialogs and popups)
  qt = {
    enable = true;
    platformTheme.name = "gtk";
    style = {
      name = "adwaita-dark";
      package = pkgs.adwaita-qt6;
    };
  };

  home.sessionVariables = {
    BROWSER = "chromium";
    GTK_THEME = "adw-gtk3-dark";
  };

  # Rebuild fontconfig cache on every activation (nixos-rebuild / home-manager switch).
  # NixOS font store paths change on rebuild; stale caches cause white squares in GTK popups.
  home.activation.refreshFontCache = lib.hm.dag.entryAfter [ "installPackages" ] ''
    run rm -rf "$HOME/.cache/fontconfig"
    run ${pkgs.fontconfig}/bin/fc-cache -f
  '';

  home.packages = with pkgs; [
    inputs.voicemode.packages.${pkgs.stdenv.hostPlatform.system}.default
    adw-gtk3
    discord
    nautilus
    dgop
    spacedrive
    figma-linux
    ghostty
    awww # Wallpaper daemon for Wayland
    (writeShellScriptBin "hypr-gemini-launch" "gemini-pwa & wezterm")
    (writeShellScriptBin "gemini-pwa" "chromium --app=https://gemini.google.com --user-data-dir=$HOME/.config/chromium-$(hostname)")
    (writeShellScriptBin "claude-pwa" "chromium --app=https://claude.ai --user-data-dir=$HOME/.config/chromium-$(hostname)")
    (writeShellScriptBin "bandlab-pwa" "chromium --app=https://www.bandlab.com --user-data-dir=$HOME/.config/chromium-$(hostname)")
    (writeShellScriptBin "set-wallpaper" ''
      #!/bin/sh
      # Set wallpaper using awww
      WALLPAPER="$HOME/.config/background"
      if [ -f "$WALLPAPER" ]; then
        ${awww}/bin/awww img "$WALLPAPER" --transition-type wipe --transition-fps 60
      fi
    '')
    (writeShellScriptBin "awww-init" ''
      #!/bin/sh
      # Wait for awww daemon to be ready and set wallpaper
      WALLPAPER="$HOME/.config/background"

      # Wait up to 10 seconds for awww daemon to be ready
      for i in $(seq 1 20); do
        if ${awww}/bin/awww query &>/dev/null; then
          break
        fi
        sleep 0.5
      done

      # Set wallpaper if file exists
      if [ -f "$WALLPAPER" ]; then
        ${awww}/bin/awww img "$WALLPAPER" --transition-type wipe --transition-fps 60
      fi
    '')
  ];

  # Default applications (force overwrites existing mimeapps.list files)
  xdg.configFile."mimeapps.list".force = true;
  xdg.dataFile."applications/mimeapps.list".force = true;
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/http" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/https" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/about" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/figma" = [ "figma.desktop" ];
      "x-terminal-emulator" = [ "ghostty.desktop" ];
      "inode/directory" = [ "Spacedrive.desktop" ];
    };
  };

  # Figma redirect (figma:// URLs open in desktop app)
  xdg.desktopEntries.figma = {
    name = "Figma";
    exec = "figma %U";
    mimeType = [ "x-scheme-handler/figma" ];
  };

  # Claude PWA (Claude.ai in app window, per-host Chrome profile)
  xdg.desktopEntries.claude-chrome = {
    name = "Claude";
    comment = "Anthropic Claude AI assistant";
    exec = "claude-pwa";
    icon = "applications-internet";
    categories = [ "Chat" ];
    startupNotify = true;
  };

  # BandLab PWA (music production web app)
  xdg.desktopEntries.bandlab-chrome = {
    name = "BandLab";
    comment = "Music production studio in your browser";
    exec = "bandlab-pwa";
    icon = "multimedia-audio-editor";
    categories = [
      "Audio"
      "AudioVideo"
    ];
    startupNotify = true;
  };

  # Wallpaper configuration - link wallpaper to expected location for awww
  xdg.configFile."background".source = ../src/nix-wallpaper-binary-black.png;

}
