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
    ./modules/kitty.nix
    ../quickshell/quickshell.nix
    ./modules/walker.nix
    ./modules/accent/accent.nix
  ];

  # Stylix target overrides
  # kitty: accent overrides are managed at runtime via accent-sync (kitty-accent.conf)
  stylix.targets.kitty.enable = false;
  # hyprland border colors are managed at runtime by hypr-accent-sync.sh + Quickshell
  stylix.targets.hyprland.enable = false;
  # micro: keep our existing colorscheme config
  stylix.targets.micro.enable = false;

  # dconf: required for portal-spawned dialogs (file picker, git popups) to pick up
  # GSettings values. Stylix manages gtk-theme, color-scheme, and font settings via dconf.
  dconf.enable = true;

  # GTK: stylix manages theme, font, and dconf color-scheme.
  # We keep icon theme (stylix doesn't manage icons) and the dark-mode hint flags.
  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = true;
    };
    gtk4 = {
      theme = null; # adopt new home-manager 26.05 default (no forced GTK3 theme on GTK4)
      extraConfig = {
        "gtk-application-prefer-dark-theme" = true;
      };
    };
  };

  # Qt: stylix manages qt.platformTheme and qt.style via its targets.qt target.

  home.sessionVariables = {
    BROWSER = "chromium";
  };

  # Rebuild fontconfig cache on every activation (nixos-rebuild / home-manager switch).
  # NixOS font store paths change on rebuild; stale caches cause white squares in GTK popups.
  home.activation.refreshFontCache = lib.hm.dag.entryAfter [ "installPackages" ] ''
    run rm -rf "$HOME/.cache/fontconfig"
    run ${pkgs.fontconfig}/bin/fc-cache -f
  '';

  home.packages = with pkgs; [
    inputs.voicemode.packages.${pkgs.stdenv.hostPlatform.system}.default
    aubio
    discord
    nautilus
    dgop
    spacedrive
    figma-linux
    ghostty
    awww # Wallpaper daemon for Wayland
    (writeShellScriptBin "hypr-gemini-launch" "gemini-pwa & kitty")
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
      "x-terminal-emulator" = [ "kitty.desktop" ];
      "inode/directory" = [ "org.gnome.Nautilus.desktop" ];
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
