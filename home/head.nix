{
  pkgs,
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
    awww # Wallpaper daemon — caches GPU textures for instant zero-flash switching
    watchexec
    wl-clipboard
    # Home-manager forces NIX_XDG_DESKTOP_PORTAL_DIR to the user profile, so the
    # xdg-desktop-portal frontend only sees portals installed here. Ship kde.portal
    # in the user profile so the Settings interface (color-scheme) is routed correctly.
    kdePackages.xdg-desktop-portal-kde
  ];

  # Wallpaper files for awww (dark/light toggle via Theme.qml)
  xdg.configFile."wallpaper-dark".source = ../src/nix-wallpaper-binary-black_8k.png;
  xdg.configFile."wallpaper-light".source = ../src/nix-wallpaper-binary-white_8k.png;

  # FluidSynth doesn't ship a .desktop entry (CLI only). Provide one so
  # MIDI files can be opened from file managers via the GM soundfont.
  xdg.desktopEntries.fluidsynth = {
    name = "FluidSynth";
    genericName = "MIDI Player";
    exec = "${pkgs.fluidsynth}/bin/fluidsynth -ni ${pkgs.soundfont-fluid}/share/soundfonts/FluidR3_GM2-2.sf2 %f";
    terminal = false;
    mimeType = [
      "audio/midi"
      "audio/x-midi"
    ];
    categories = [
      "Audio"
      "AudioVideo"
    ];
  };

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
      "x-terminal-emulator" = [ "Alacritty.desktop" ];
      "inode/directory" = [ "org.kde.dolphin.desktop" ];
      "application/pdf" = [ "org.kde.okular.desktop" ];
      "audio/midi" = [ "fluidsynth.desktop" ];
      "audio/x-midi" = [ "fluidsynth.desktop" ];
    };
  };

}
