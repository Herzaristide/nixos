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
    code-cursor
    google-chrome
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    ghostty
    (writeShellScriptBin "hypr-gemini-launch" ''
      google-chrome-stable --app=https://gemini.google.com --user-data-dir="$HOME/.config/google-chrome-$(hostname)" &
      ghostty --class=gemini-term &
    '')
    (writeShellScriptBin "gemini-chrome" ''
      exec google-chrome-stable --app=https://gemini.google.com --user-data-dir="$HOME/.config/google-chrome-$(hostname)"
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
      "text/html" = [ "google-chrome.desktop" ];
      "x-scheme-handler/http" = [ "google-chrome.desktop" ];
      "x-scheme-handler/https" = [ "google-chrome.desktop" ];
      "x-scheme-handler/about" = [ "google-chrome.desktop" ];
      "x-terminal-emulator" = [ "ghostty.desktop" ];
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
}
