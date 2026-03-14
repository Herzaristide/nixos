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

  # Quickshell bar (beautiful bottom bar with system monitoring)
  # Features: workspaces, window title, system tray, CPU/RAM stats,
  # network status, audio control, battery indicator, and clock
  xdg.configFile."quickshell/bar.qml".source = ./widget/bar.qml;
  xdg.configFile."quickshell/QuickShellBar.qml".source = ./widget/QuickShellBar.qml;
  xdg.configFile."quickshell/components/qmldir".source = ./widget/components/qmldir;
  xdg.configFile."quickshell/components/Workspaces.qml".source = ./widget/components/Workspaces.qml;
  xdg.configFile."quickshell/components/WindowTitle.qml".source = ./widget/components/WindowTitle.qml;
  xdg.configFile."quickshell/components/SystemTrayComponent.qml".source =
    ./widget/components/SystemTrayComponent.qml;
  xdg.configFile."quickshell/components/SystemStats.qml".source = ./widget/components/SystemStats.qml;
  xdg.configFile."quickshell/components/Network.qml".source = ./widget/components/Network.qml;
  xdg.configFile."quickshell/components/Microphone.qml".source = ./widget/components/Microphone.qml;
  xdg.configFile."quickshell/components/Audio.qml".source = ./widget/components/Audio.qml;
  xdg.configFile."quickshell/components/Battery.qml".source = ./widget/components/Battery.qml;
  xdg.configFile."quickshell/components/Clock.qml".source = ./widget/components/Clock.qml;

  # Headful (GUI) packages for desktop/laptop systems
  # adw-gtk3, qt6ct: required for DMS matugen GTK/Qt application theming
  # material-symbols: icon font for Quickshell bar
  home.packages = with pkgs; [
    inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
    inputs.voicemode.packages.${pkgs.stdenv.hostPlatform.system}.default
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
    figma-linux
    ghostty
    material-symbols
    swww # Wallpaper daemon for Wayland
    (writeShellScriptBin "hypr-claude-launch"
      "claude-pwa & wezterm")
    (writeShellScriptBin "claude-pwa"
      "google-chrome-stable --app=https://claude.ai --user-data-dir=$HOME/.config/google-chrome-$(hostname)")
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

  # Claude PWA (Claude.ai in app window, per-host Chrome profile)
  xdg.desktopEntries.claude-chrome = {
    name = "Claude";
    comment = "Anthropic Claude AI assistant";
    exec = "claude-pwa";
    icon = "applications-internet";
    categories = [ "Chat" ];
    startupNotify = true;
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
