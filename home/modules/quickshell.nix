{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  # QuickShell configured without interface
  home.packages = with pkgs; [
    inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  # Minimal QuickShell config (no visible interface)
  xdg.configFile."quickshell/shell.qml".source = ../quickshell-launcher/shell.qml;

  # Systemd user service to auto-start quickshell
  systemd.user.services.quickshell = {
    Unit = {
      Description = "QuickShell (headless)";
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
