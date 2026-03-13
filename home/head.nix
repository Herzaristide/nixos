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

  # Quickshell bar (simple bottom bar)
  xdg.configFile."quickshell/bar.qml" = {
    text = ''
      import Quickshell
      import Quickshell.Wayland
      import QtQuick
      import QtQuick.Layouts

      PanelWindow {
        anchors.bottom: true
        anchors.left: true
        anchors.right: true
        implicitHeight: 30
        color: "#1a1b26"

        RowLayout {
          anchors.fill: parent
          anchors.margins: 8
          spacing: 8

          Text {
            text: "Quickshell"
            color: "#a9b1d6"
            font.pixelSize: 14
          }

          Item { Layout.fillWidth: true }

          Text {
            id: clock
            color: "#a9b1d6"
            font.pixelSize: 14
            text: Qt.formatDateTime(new Date(), "HH:mm")
            Timer {
              interval: 1000
              running: true
              repeat: true
              onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
            }
          }
        }
      }
    '';
  };

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
