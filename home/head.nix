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
    ./modules/wezterm.nix
    ./modules/quickshell.nix
    ./modules/rofi.nix
  ];

  # Mouse cursor theme (Hyprland, GTK apps)
  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.phinger-cursors;
    name = "phinger-cursors-dark";
    size = 32;
  };

  # Dark mode system-wide (GTK, GNOME apps, XDG portal, Chromium)
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    gtk-theme = "adw-gtk3-dark";
  };
  gtk = {
    enable = true;
    font = {
      name = "DejaVu Sans";
      size = 11;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = true;
    };
    gtk4.extraConfig = {
      "gtk-application-prefer-dark-theme" = true;
    };
  };

  home.sessionVariables = {
    BROWSER = "chromium";
    GTK_THEME = "adw-gtk3-dark";
  };

  # OLD Quickshell config (replaced by kurukurubar from Zaphkiel)
  # Uncomment below if you want to revert to the custom bar
  # xdg.configFile."quickshell/bar.qml".source = ./widget/bar.qml;
  # xdg.configFile."quickshell/QuickShellBar.qml".source = ./widget/QuickShellBar.qml;
  # xdg.configFile."quickshell/components/qmldir".source = ./widget/components/qmldir;
  # xdg.configFile."quickshell/components/Workspaces.qml".source = ./widget/components/Workspaces.qml;
  # xdg.configFile."quickshell/components/WindowTitle.qml".source = ./widget/components/WindowTitle.qml;
  # xdg.configFile."quickshell/components/SystemTrayComponent.qml".source =
  #   ./widget/components/SystemTrayComponent.qml;
  # xdg.configFile."quickshell/components/SystemStats.qml".source = ./widget/components/SystemStats.qml;
  # xdg.configFile."quickshell/components/Network.qml".source = ./widget/components/Network.qml;
  # xdg.configFile."quickshell/components/Microphone.qml".source = ./widget/components/Microphone.qml;
  # xdg.configFile."quickshell/components/Audio.qml".source = ./widget/components/Audio.qml;
  # xdg.configFile."quickshell/components/Battery.qml".source = ./widget/components/Battery.qml;
  # xdg.configFile."quickshell/components/Clock.qml".source = ./widget/components/Clock.qml;

  # Headful (GUI) packages for desktop/laptop systems
  # adw-gtk3, qt6ct: required for DMS matugen GTK/Qt application theming
  # material-symbols: icon font for Quickshell bar
  home.packages = with pkgs; [
    inputs.claude-desktop.packages.${pkgs.stdenv.hostPlatform.system}.default
    # inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default  # Now using kurukurubar
    inputs.voicemode.packages.${pkgs.stdenv.hostPlatform.system}.default
    adw-gtk3
    discord
    qt6Packages.qt6ct
    dgop
    nautilus
    gnome-online-accounts # Google Drive in Nautilus via Settings > Online Accounts
    gnome-control-center # Add Google account: run "gnome-control-center" → Online Accounts
    code-cursor
    (pkgs.vscode-with-extensions.override {
      vscodeExtensions = (import ./modules/vscode/vscode-settings.nix { inherit pkgs; }).extensions;
    })
    figma-linux
    ghostty
    (writeShellScriptBin "hypr-claude-launch" "claude-pwa & wezterm")
    (writeShellScriptBin "claude-pwa" "chromium --app=https://claude.ai --user-data-dir=$HOME/.config/chromium-$(hostname)")
    (writeShellScriptBin "bandlab-pwa" "chromium --app=https://www.bandlab.com --user-data-dir=$HOME/.config/chromium-$(hostname)")
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
      "x-scheme-handler/cursor" = [ "cursor.desktop" ];
      "x-terminal-emulator" = [ "ghostty.desktop" ];
      "inode/directory" = [ "yazi.desktop" ];
      "x-scheme-handler/file" = [ "yazi.desktop" ];
    };
  };

  # Figma redirect (figma:// URLs open in desktop app)
  xdg.desktopEntries.figma = {
    name = "Figma";
    exec = "figma %U";
    mimeType = [ "x-scheme-handler/figma" ];
  };

  # Cursor redirect (cursor:// URLs open in Cursor IDE)
  xdg.desktopEntries.cursor = {
    name = "Cursor";
    exec = "cursor %U";
    mimeType = [ "x-scheme-handler/cursor" ];
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

}
