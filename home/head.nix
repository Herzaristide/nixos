{
  config,
  pkgs,
  inputs,
  lib,
  darkMode ? true,
  ...
}:

{
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

  # NixOS font store paths change on rebuild; stale caches cause white squares in GTK popups.
  home.activation.refreshFontCache = lib.hm.dag.entryAfter [ "installPackages" ] ''
    run rm -rf "$HOME/.cache/fontconfig"
    run ${pkgs.fontconfig}/bin/fc-cache -f
  '';

  home.packages = with pkgs; [
    inputs.explorer.packages.${pkgs.stdenv.hostPlatform.system}.file-explorer
    nautilus
    vesktop
    awww # Wallpaper daemon — caches GPU textures for instant zero-flash switching
  ];

  # Wallpaper files for awww (dark/light toggle via Theme.qml)
  xdg.configFile."wallpaper-dark".source = ../src/nix-wallpaper-binary-black_8k.png;
  xdg.configFile."wallpaper-light".source = ../src/nix-wallpaper-binary-white_8k.png;

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
