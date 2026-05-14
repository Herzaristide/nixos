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
    ./modules/code/vscode/vscode.nix
    ./modules/wezterm.nix
    ../quickshell/quickshell.nix
    ./modules/walker.nix
    ./modules/accent/accent.nix
    ./modules/kde.nix
    ./modules/chromium.nix
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
    inputs.explorer.packages.${pkgs.stdenv.hostPlatform.system}.file-explorer
    nautilus
    aubio
    vesktop
    dgop
    awww # Wallpaper daemon — caches GPU textures for instant zero-flash switching
  ];

  # Wallpaper files for awww (dark/light toggle via Theme.qml)
  xdg.configFile."wallpaper-dark".source = ../src/nix-wallpaper-binary-black_2k.png;
  xdg.configFile."wallpaper-light".source = ../src/nix-wallpaper-binary-white_2k.png;

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
      "x-scheme-handler/unknown" = [ "chromium-browser.desktop" ];
      "x-scheme-handler/figma" = [ "figma.desktop" ];
      "x-terminal-emulator" = [ "org.wezfurlong.wezterm.desktop" ];
      "inode/directory" = [ "file-explorer.desktop" ];
    };
  };

  # Custom file explorer
  xdg.desktopEntries.file-explorer = {
    name = "File Explorer";
    comment = "Explorateur de fichiers natif";
    exec = "file-explorer %u";
    icon = "system-file-manager";
    categories = [
      "System"
      "FileManager"
    ];
    mimeType = [ "inode/directory" ];
    startupNotify = true;
  };

}
