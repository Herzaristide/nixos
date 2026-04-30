{
  config,
  pkgs,
  lib,
  inputs,
  palette,
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
  xdg.configFile."quickshell/OllamaTools.qml".source = ./OllamaTools.qml;
  xdg.configFile."quickshell/QuickControls.qml".source = ./QuickControls.qml;
  xdg.configFile."quickshell/NotesWidget.qml".source = ./NotesWidget.qml;
  xdg.configFile."quickshell/HardwareStats.qml".source = ./HardwareStats.qml;
  xdg.configFile."quickshell/MiniGraph.qml".source = ./MiniGraph.qml;
  xdg.configFile."quickshell/voice-assistant.sh" = {
    source = ./voice-assistant.sh;
    executable = true;
  };
  xdg.configFile."quickshell/PitchAnalyzer.qml".source = ./PitchAnalyzer.qml;
  xdg.configFile."quickshell/MusicPlayerWidget.qml".source = ./MusicPlayerWidget.qml;
  xdg.configFile."quickshell/pitch-analyzer.sh" = {
    source = ./pitch-analyzer.sh;
    executable = true;
  };
  xdg.configFile."quickshell/nixos.svg".source =
    "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";

  # Theme.qml: the @PALETTE_ACCENT@ placeholder is replaced at build time with
  # the base0D color from palette.nix, so the default accent color always matches
  # the system palette. The user can still override it at runtime via Settings.
  xdg.configFile."quickshell/Theme.qml".text =
    builtins.replaceStrings [ "@PALETTE_ACCENT@" ] [ "#${palette.base0D}" ]
      (builtins.readFile ./Theme.qml);

  xdg.configFile."quickshell/qmldir".source = ./qmldir;

  # Note: Quickshell is started via Hyprland's exec-once (see home/modules/hyprland.nix)
  # No systemd service needed - that would run it twice!
}
