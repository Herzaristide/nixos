{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # QuickShell launcher bar - simple bottom bar with application search
  home.packages = with pkgs; [
    inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Copy launcher QML files to ~/.config/quickshell
  xdg.configFile."quickshell/shell.qml".source = ../quickshell-launcher/shell.qml;
  xdg.configFile."quickshell/LauncherBar.qml".source = ../quickshell-launcher/LauncherBar.qml;

  # Systemd user service to auto-start quickshell
  systemd.user.services.quickshell = {
    Unit = {
      Description = "QuickShell launcher bar";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${
        inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
      }/bin/quickshell";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
