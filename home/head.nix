{
  config,
  pkgs,
  inputs,
  lib,
  darkMode ? true,
  ...
}:

{
  imports = [
    ./modules/hyprland.nix
    ./modules/vscode/vscode.nix
    ./modules/wezterm.nix
    ./modules/zen.nix
    ../quickshell/quickshell.nix
    ./modules/walker.nix
    ./modules/accent/accent.nix
    ./modules/kde.nix
  ];

  # dconf: required for portal-spawned dialogs (file picker, git popups) to pick up
  # GSettings values (gtk-theme, color-scheme, font settings).
  dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = if darkMode then "prefer-dark" else "prefer-light";
      font-name = "JetBrains Mono 11";
      document-font-name = "JetBrains Mono 11";
      monospace-font-name = "JetBrains Mono 11";
    };
  };

  # Cursor theme
  home.pointerCursor = {
    package = pkgs.phinger-cursors;
    name = if darkMode then "phinger-cursors-dark" else "phinger-cursors";
    size = 32;
    gtk.enable = true;
  };

  home.sessionVariables = {
    BROWSER = "chromium";
  };

  # NixOS font store paths change on rebuild; stale caches cause white squares in GTK popups.
  home.activation.refreshFontCache = lib.hm.dag.entryAfter [ "installPackages" ] ''
    run rm -rf "$HOME/.cache/fontconfig"
    run ${pkgs.fontconfig}/bin/fc-cache -f
  '';

  home.packages = with pkgs; [
    inputs.voicemode.packages.${pkgs.stdenv.hostPlatform.system}.default
    aubio
    vesktop
    dgop
    spacedrive
    figma-linux
    teams-for-linux
    awww # Wallpaper daemon for Wayland
    (writeShellScriptBin "hypr-claude-launch" "claude-pwa")
    (writeShellScriptBin "hypr-gemini-launch" "gemini-pwa")
    (writeShellScriptBin "gemini-pwa" "chromium --app=https://gemini.google.com --user-data-dir=$HOME/.config/chromium-$(hostname) --enable-features=WebUIDarkMode --force-dark-mode")
    (writeShellScriptBin "claude-pwa" "chromium --app=https://claude.ai --user-data-dir=$HOME/.config/chromium-$(hostname) --enable-features=WebUIDarkMode --force-dark-mode")
    (writeShellScriptBin "bandlab-pwa" "chromium --app=https://www.bandlab.com --user-data-dir=$HOME/.config/chromium-$(hostname) --enable-features=WebUIDarkMode --force-dark-mode")
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
      "x-terminal-emulator" = [ "org.wezfurlong.wezterm.desktop" ];
      "inode/directory" = [ "org.kde.dolphin.desktop" ];
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

  # Wallpaper configuration — default startup wallpaper and mode-specific variants
  xdg.configFile."background".source = ../src/nix-wallpaper-binary-black_8k.png;
  xdg.configFile."wallpaper-dark".source = ../src/nix-wallpaper-binary-black_8k.png;
  xdg.configFile."wallpaper-light".source = ../src/nix-wallpaper-binary-white_8k.png;

}
