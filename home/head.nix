{ config, pkgs, ... }:

{
  imports = [
    ./modules/hyprland.nix
  ];

  # Headful (GUI) packages for desktop/laptop systems
  home.packages = with pkgs; [
    code-cursor
    google-chrome
    ghostty
    (writeShellScriptBin "hypr-gemini-launch" ''
      google-chrome-stable --app=https://gemini.google.com --user-data-dir="$HOME/.config/google-chrome-$(hostname)" &
      ghostty --class=gemini-term &
    '')
    (writeShellScriptBin "gemini-chrome" ''
      exec google-chrome-stable --app=https://gemini.google.com --user-data-dir="$HOME/.config/google-chrome-$(hostname)"
    '')
  ];

  # Default applications
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
    categories = [ "Network" "Chat" ];
    startupNotify = true;
  };
}
