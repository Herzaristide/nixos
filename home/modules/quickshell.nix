{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # Local declarative kurukurubar configuration (bottom-positioned bar)
  home.packages = with pkgs; [
    inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default # Quickshell runtime

    # Optional but recommended dependencies
    brightnessctl # For brightness control widget
    power-profiles-daemon # For power profile management
    # rembg                # For foreground layer effect (heavy dependency)

    # Matugen for wallpaper-based color theming
    matugen
  ];

  # Note: material-symbols and nerd-fonts.caskaydia-mono are installed
  # system-wide in /etc/nixos/modules/head.nix for proper fontconfig integration

  # Copy all kurukurubar files to ~/.config/quickshell
  xdg.configFile."quickshell/shell.qml".source = ../kurukurubar/shell.qml;
  xdg.configFile."quickshell/greeter.qml".source = ../kurukurubar/greeter.qml;

  # Containers
  xdg.configFile."quickshell/Containers/qmldir".source = ../kurukurubar/Containers/qmldir;
  xdg.configFile."quickshell/Containers/CentralSwipable.qml".source =
    ../kurukurubar/Containers/CentralSwipable.qml;
  xdg.configFile."quickshell/Containers/Inbox.qml".source = ../kurukurubar/Containers/Inbox.qml;
  xdg.configFile."quickshell/Containers/KuruKuru.qml".source = ../kurukurubar/Containers/KuruKuru.qml;
  xdg.configFile."quickshell/Containers/LockScreenSurface.qml".source =
    ../kurukurubar/Containers/LockScreenSurface.qml;
  xdg.configFile."quickshell/Containers/Popup.qml".source = ../kurukurubar/Containers/Popup.qml;
  xdg.configFile."quickshell/Containers/Primary.qml".source = ../kurukurubar/Containers/Primary.qml;
  xdg.configFile."quickshell/Containers/TopBar.qml".source = ../kurukurubar/Containers/TopBar.qml;

  # Data modules
  xdg.configFile."quickshell/Data/qmldir".source = ../kurukurubar/Data/qmldir;
  xdg.configFile."quickshell/Data/Audio.qml".source = ../kurukurubar/Data/Audio.qml;
  xdg.configFile."quickshell/Data/Brightness.qml".source = ../kurukurubar/Data/Brightness.qml;
  xdg.configFile."quickshell/Data/Clock.qml".source = ../kurukurubar/Data/Clock.qml;
  xdg.configFile."quickshell/Data/Colors.qml".source = ../kurukurubar/Data/Colors.qml;
  xdg.configFile."quickshell/Data/Config.qml".source = ../kurukurubar/Data/Config.qml;
  xdg.configFile."quickshell/Data/Globals.qml".source = ../kurukurubar/Data/Globals.qml;
  xdg.configFile."quickshell/Data/MangoWC.qml".source = ../kurukurubar/Data/MangoWC.qml;
  xdg.configFile."quickshell/Data/MaterialEasing.qml".source = ../kurukurubar/Data/MaterialEasing.qml;
  xdg.configFile."quickshell/Data/NotifServer.qml".source = ../kurukurubar/Data/NotifServer.qml;
  xdg.configFile."quickshell/Data/Paths.qml".source = ../kurukurubar/Data/Paths.qml;
  xdg.configFile."quickshell/Data/Recording.qml".source = ../kurukurubar/Data/Recording.qml;
  xdg.configFile."quickshell/Data/Resources.qml".source = ../kurukurubar/Data/Resources.qml;
  xdg.configFile."quickshell/Data/SessionActions.qml".source = ../kurukurubar/Data/SessionActions.qml;

  # Generics
  xdg.configFile."quickshell/Generics/qmldir".source = ../kurukurubar/Generics/qmldir;
  xdg.configFile."quickshell/Generics/AudioSlider.qml".source =
    ../kurukurubar/Generics/AudioSlider.qml;
  xdg.configFile."quickshell/Generics/BarCode.qml".source = ../kurukurubar/Generics/BarCode.qml;
  xdg.configFile."quickshell/Generics/CircularProgress.qml".source =
    ../kurukurubar/Generics/CircularProgress.qml;
  xdg.configFile."quickshell/Generics/GradientText.qml".source =
    ../kurukurubar/Generics/GradientText.qml;
  xdg.configFile."quickshell/Generics/MatIcon.qml".source = ../kurukurubar/Generics/MatIcon.qml;
  xdg.configFile."quickshell/Generics/MouseArea.qml".source = ../kurukurubar/Generics/MouseArea.qml;
  xdg.configFile."quickshell/Generics/Notification.qml".source =
    ../kurukurubar/Generics/Notification.qml;
  xdg.configFile."quickshell/Generics/NotificationPopup.qml".source =
    ../kurukurubar/Generics/NotificationPopup.qml;
  xdg.configFile."quickshell/Generics/ToggleButton.qml".source =
    ../kurukurubar/Generics/ToggleButton.qml;
  xdg.configFile."quickshell/Generics/TweakToggle.qml".source =
    ../kurukurubar/Generics/TweakToggle.qml;

  # Layers (includes modified Notch.qml with bottom positioning)
  xdg.configFile."quickshell/Layers/qmldir".source = ../kurukurubar/Layers/qmldir;
  xdg.configFile."quickshell/Layers/LockScreen.qml".source = ../kurukurubar/Layers/LockScreen.qml;
  xdg.configFile."quickshell/Layers/MouseParticles.qml".source =
    ../kurukurubar/Layers/MouseParticles.qml;
  xdg.configFile."quickshell/Layers/Notch.qml".source = ../kurukurubar/Layers/Notch.qml;
  xdg.configFile."quickshell/Layers/PseudoReserved.qml".source =
    ../kurukurubar/Layers/PseudoReserved.qml;
  xdg.configFile."quickshell/Layers/Wallpaper.qml".source = ../kurukurubar/Layers/Wallpaper.qml;

  # Widgets
  xdg.configFile."quickshell/Widgets/qmldir".source = ../kurukurubar/Widgets/qmldir;
  xdg.configFile."quickshell/Widgets/AudioSwiper.qml".source = ../kurukurubar/Widgets/AudioSwiper.qml;
  xdg.configFile."quickshell/Widgets/AudioTab.qml".source = ../kurukurubar/Widgets/AudioTab.qml;
  xdg.configFile."quickshell/Widgets/BatteryPill.qml".source = ../kurukurubar/Widgets/BatteryPill.qml;
  xdg.configFile."quickshell/Widgets/BrightnessDot.qml".source =
    ../kurukurubar/Widgets/BrightnessDot.qml;
  xdg.configFile."quickshell/Widgets/CalendarView.qml".source =
    ../kurukurubar/Widgets/CalendarView.qml;
  xdg.configFile."quickshell/Widgets/GreeterWidget.qml".source =
    ../kurukurubar/Widgets/GreeterWidget.qml;
  xdg.configFile."quickshell/Widgets/HomeView.qml".source = ../kurukurubar/Widgets/HomeView.qml;
  xdg.configFile."quickshell/Widgets/KuruParticleSystem.qml".source =
    ../kurukurubar/Widgets/KuruParticleSystem.qml;
  xdg.configFile."quickshell/Widgets/KuruTweaksTab.qml".source =
    ../kurukurubar/Widgets/KuruTweaksTab.qml;
  xdg.configFile."quickshell/Widgets/MprisDot.qml".source = ../kurukurubar/Widgets/MprisDot.qml;
  xdg.configFile."quickshell/Widgets/MprisItem.qml".source = ../kurukurubar/Widgets/MprisItem.qml;
  xdg.configFile."quickshell/Widgets/MusicView.qml".source = ../kurukurubar/Widgets/MusicView.qml;
  xdg.configFile."quickshell/Widgets/NotifDots.qml".source = ../kurukurubar/Widgets/NotifDots.qml;
  xdg.configFile."quickshell/Widgets/PowerInfo.qml".source = ../kurukurubar/Widgets/PowerInfo.qml;
  xdg.configFile."quickshell/Widgets/PowerTab.qml".source = ../kurukurubar/Widgets/PowerTab.qml;
  xdg.configFile."quickshell/Widgets/RecordingDot.qml".source =
    ../kurukurubar/Widgets/RecordingDot.qml;
  xdg.configFile."quickshell/Widgets/SessionDots.qml".source = ../kurukurubar/Widgets/SessionDots.qml;
  xdg.configFile."quickshell/Widgets/SettingsView.qml".source =
    ../kurukurubar/Widgets/SettingsView.qml;
  xdg.configFile."quickshell/Widgets/SystemView.qml".source = ../kurukurubar/Widgets/SystemView.qml;
  xdg.configFile."quickshell/Widgets/TimePill.qml".source = ../kurukurubar/Widgets/TimePill.qml;
  xdg.configFile."quickshell/Widgets/TrayItem.qml".source = ../kurukurubar/Widgets/TrayItem.qml;
  xdg.configFile."quickshell/Widgets/TrayItemMenu.qml".source =
    ../kurukurubar/Widgets/TrayItemMenu.qml;
  xdg.configFile."quickshell/Widgets/Wallpaper.qml".source = ../kurukurubar/Widgets/Wallpaper.qml;
  xdg.configFile."quickshell/Widgets/WorkspacePill.qml".source =
    ../kurukurubar/Widgets/WorkspacePill.qml;
  xdg.configFile."quickshell/Widgets/WorkspaceSelector.qml".source =
    ../kurukurubar/Widgets/WorkspaceSelector.qml;

  # Assets
  xdg.configFile."quickshell/Assets/AlbumCover-by-Squirrel-Modeller.svg".source =
    ../kurukurubar/Assets/AlbumCover-by-Squirrel-Modeller.svg;

  # Scripts
  xdg.configFile."quickshell/scripts/cacheImg.sh".source = ../kurukurubar/scripts/cacheImg.sh;
  xdg.configFile."quickshell/scripts/extractFg.sh".source = ../kurukurubar/scripts/extractFg.sh;
  xdg.configFile."quickshell/scripts/session.sh".source = ../kurukurubar/scripts/session.sh;

  # Set wallpaper for kurukurubar to use
  xdg.configFile."background".source = "${inputs.self}/src/wallpaper.jpg";

  # Matugen config files removed - we use jq transformation instead due to matugen 3.1.0 template bug
  # xdg.configFile."matugen/config.toml".source = ../kurukurubar/matugen-config.toml;
  # xdg.configFile."matugen/templates/quickshell-colors.json".source =
  #   ../kurukurubar/matugen-template.qml;

  # Systemd service to run matugen on wallpaper change
  systemd.user.services.matugen-kurukurubar = {
    Unit = {
      Description = "Generate Quickshell colors from wallpaper using matugen";
      After = [ "graphical-session-pre.target" ];
    };
    Service = {
      Type = "oneshot";
      # Workaround for matugen 3.1.0 template bug: use jq to transform JSON directly
      # instead of relying on broken template processing
      ExecStart = pkgs.writeShellScript "matugen-kurukurubar" ''
        ${pkgs.matugen}/bin/matugen image ${config.home.homeDirectory}/.config/background --json hex -t scheme-tonal-spot 2>/dev/null | \
        ${pkgs.jq}/bin/jq '{
          colors: {
            dark: (.colors | to_entries | map({key: .key, value: .value.dark}) | from_entries),
            light: (.colors | to_entries | map({key: .key, value: .value.light}) | from_entries)
          }
        }' > ${config.home.homeDirectory}/.config/kurukurubar/colors.json
      '';
      RemainAfterExit = true;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
