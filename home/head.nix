{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./modules/hyprland.nix
    ./modules/waybar.nix
  ];

  # Headful (GUI) packages for desktop/laptop systems
  home.packages = with pkgs; [
    nautilus
    gnome-online-accounts  # Google Drive in Nautilus via Settings > Online Accounts
    gnome-control-center   # Add Google account: run "gnome-control-center" → Online Accounts
    code-cursor
    cursor-cli
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

  # Force-overwrite config files managed by Stylix (they may already exist on disk)
  xdg.configFile."gtk-3.0/settings.ini".force = true;
  xdg.configFile."gtk-3.0/gtk.css".force = true;
  xdg.configFile."gtk-4.0/settings.ini".force = true;
  xdg.configFile."gtk-4.0/gtk.css".force = true;
  xdg.configFile."qt5ct/qt5ct.conf".force = true;
  xdg.configFile."qt6ct/qt6ct.conf".force = true;

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
    categories = [ "Audio" "Music" "Network" ];
    startupNotify = true;
  };

  # Online Accounts - add Google Drive for Nautilus (opens GNOME Settings → Online Accounts)
  xdg.desktopEntries.online-accounts = {
    name = "Online Accounts";
    comment = "Add Google Drive and other cloud accounts for Nautilus";
    exec = "gnome-control-center online-accounts";
    icon = "org.gnome.Settings-online-accounts-symbolic";
    categories = [ "Settings" "System" ];
    startupNotify = true;
  };

  # Eraser PWA (Chrome in app mode) - diagrams & docs for engineering teams
  xdg.desktopEntries.eraser = {
    name = "Eraser";
    comment = "AI co-pilot for technical design and documentation";
    exec = "eraser-chrome";
    icon = "google-chrome";
    categories = [ "Development" "Graphics" "Network" ];
    startupNotify = true;
  };

  # Set environment variables for Cursor/VSCode to use Firefox for opening links
  home.sessionVariables = {
    BROWSER = "firefox";
  };
}
