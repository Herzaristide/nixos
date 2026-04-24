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

  # Minimal QuickShell config (bottom bar)
  xdg.configFile."quickshell/shell.qml".source = ./shell.qml;
  xdg.configFile."quickshell/BottomBar.qml".source = ./BottomBar.qml;
  xdg.configFile."quickshell/SidePanel.qml".source = ./SidePanel.qml;
  xdg.configFile."quickshell/OllamaChat.qml".source = ./OllamaChat.qml;
  xdg.configFile."quickshell/NotesWidget.qml".source = ./NotesWidget.qml;
  xdg.configFile."quickshell/nixos.svg".source =
    "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";

  # Note: Quickshell is started via Hyprland's exec-once (see home/modules/hyprland.nix)
  # No systemd service needed - that would run it twice!
}
