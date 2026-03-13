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
    ./modules/vscode.nix
    ./modules/wezterm.nix
  ];

  # Mouse cursor theme (Hyprland, GTK apps)
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.phinger-cursors;
    name = "phinger-cursors-dark";
    size = 32;
  };

  # Dark mode by default (GTK, GNOME apps, XDG portal)
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };
  gtk.gtk3.extraConfig = {
    "gtk-application-prefer-dark-theme" = true;
  };

  # Quickshell bar (workspace-enabled bottom bar)
  # Creates bars on both HDMI-A-1 (external) and eDP-1 (laptop)
  # Shows Hyprland workspaces 1-5 with click-to-switch functionality
  xdg.configFile."quickshell/bar.qml".source = ./widget/bar.qml;
  xdg.configFile."quickshell/QuickShellBar.qml".source = ./widget/QuickShellBar.qml;

  # Headful (GUI) packages for desktop/laptop systems
  # adw-gtk3, qt6ct: required for DMS matugen GTK/Qt application theming
  home.packages = with pkgs; [
    inputs.claude-desktop.packages.${pkgs.system}.default
    inputs.quickshell.packages.${pkgs.system}.default
    adw-gtk3
    discord
    qt6Packages.qt6ct
    dgop
    nautilus
    gnome-online-accounts # Google Drive in Nautilus via Settings > Online Accounts
    gnome-control-center # Add Google account: run "gnome-control-center" → Online Accounts
    code-cursor
    google-chrome
    firefox
    ghostty
    (writeShellScriptBin "hypr-claude-launch" ''
      claude-desktop &
      ghostty --class=claude-term &
    '')
  ];

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

  # Online Accounts - add Google Drive for Nautilus (opens GNOME Settings → Online Accounts)
  xdg.desktopEntries.online-accounts = {
    name = "Online Accounts";
    comment = "Add Google Drive and other cloud accounts for Nautilus";
    exec = "gnome-control-center online-accounts";
    icon = "org.gnome.Settings-online-accounts-symbolic";
    categories = [
      "Settings"
      "System"
    ];
    startupNotify = true;
  };

  # Set environment variables for Cursor/VSCode to use Firefox for opening links
  home.sessionVariables = {
    BROWSER = "google-chrome";
  };
}
