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
