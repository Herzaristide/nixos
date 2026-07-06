{
  config,
  pkgs,
  lib,
  inputs,
  primaryMonitor ? "HDMI-A-1",
  ...
}:

let
  # Interface Quickshell (QML/scripts/assets) — dépôt séparé, tiré comme input
  # de flake (`flake = false`). Voir flake.nix. Cette glue installe les fichiers
  # dans ~/.config/quickshell et référence le paquet quickshell amont.
  src = inputs.karenine;
in
{
  # QuickShell configured without interface
  # NB: pas de `python3` ici — les scripts qui ont besoin de numpy
  # (chroma-analyzer.sh, mic-level.sh) référencent leur propre env Python
  # via chemin absolu du store (cf. plus bas), donc rien à exposer sur PATH.
  home.packages = with pkgs; [
    inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default
    cava # audio-spectrum source for the music widget EQ bars
    pulseaudio # provides parec/pactl used by chroma-analyzer.sh
  ];

  # Minimal QuickShell config (bottom bar)
  xdg.configFile."quickshell/shell.qml".text =
    builtins.replaceStrings [ "@PRIMARY_MONITOR@" ] [ primaryMonitor ]
      (builtins.readFile "${src}/shell.qml");
  xdg.configFile."quickshell/BottomBar.qml".source = "${src}/BottomBar.qml";
  xdg.configFile."quickshell/SidePanel.qml".source = "${src}/SidePanel.qml";
  xdg.configFile."quickshell/RightPanel.qml".source = "${src}/RightPanel.qml";
  xdg.configFile."quickshell/Settings.qml".source = "${src}/Settings.qml";
  xdg.configFile."quickshell/SettingsWindow.qml".source = "${src}/SettingsWindow.qml";
  xdg.configFile."quickshell/OllamaChat.qml".source = "${src}/OllamaChat.qml";
  xdg.configFile."quickshell/OllamaTools.qml".source = "${src}/OllamaTools.qml";
  xdg.configFile."quickshell/ClaudeChat.qml".source = "${src}/ClaudeChat.qml";
  xdg.configFile."quickshell/AIPanel.qml".source = "${src}/AIPanel.qml";
  xdg.configFile."quickshell/QuickControls.qml".source = "${src}/QuickControls.qml";
  xdg.configFile."quickshell/NotesWidget.qml".source = "${src}/NotesWidget.qml";
  xdg.configFile."quickshell/HardwareStats.qml".source = "${src}/HardwareStats.qml";
  xdg.configFile."quickshell/MiniGraph.qml".source = "${src}/MiniGraph.qml";
  xdg.configFile."quickshell/voice-assistant.sh" = {
    source = "${src}/voice-assistant.sh";
    executable = true;
  };
  xdg.configFile."quickshell/mic-level.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Wrapper that pins parec/python paths from the Nix store before
      # delegating to the actual mic-level script.
      export PAREC_BIN="${pkgs.pulseaudio}/bin/parec"
      export PYTHON_BIN="${pkgs.python3.withPackages (_: [ ])}/bin/python3"
      exec bash ${src}/mic-level.sh
    '';
    executable = true;
  };
  xdg.configFile."quickshell/Metronome.qml".source = "${src}/Metronome.qml";
  xdg.configFile."quickshell/Tuner.qml".source = "${src}/Tuner.qml";
  xdg.configFile."quickshell/MusicPlayerWidget.qml".source = "${src}/MusicPlayerWidget.qml";
  xdg.configFile."quickshell/ChromaGraph.qml".source = "${src}/ChromaGraph.qml";
  xdg.configFile."quickshell/metronome.sh" = {
    source = "${src}/metronome.sh";
    executable = true;
  };
  xdg.configFile."quickshell/chroma-analyzer.py".source = "${src}/chroma-analyzer.py";
  xdg.configFile."quickshell/chroma-analyzer.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Capture the default sink monitor (what the system is playing) and
      # stream raw mono PCM into the python chroma analyzer.
      set -u
      SINK="$(${pkgs.pulseaudio}/bin/pactl get-default-sink 2>/dev/null)"
      if [ -z "$SINK" ]; then
        echo "STATUS:READY"
        exec sleep infinity
      fi
      exec ${pkgs.pulseaudio}/bin/parec \
            --device="''${SINK}.monitor" \
            --rate=22050 --channels=1 --format=s16le --raw \
            2>/dev/null \
        | ${pkgs.python3.withPackages (ps: [ ps.numpy ])}/bin/python3 \
            "$HOME/.config/quickshell/chroma-analyzer.py"
    '';
    executable = true;
  };
  xdg.configFile."quickshell/tuner.py".source = "${src}/tuner.py";
  xdg.configFile."quickshell/tuner.sh" = {
    text = ''
      #!/usr/bin/env bash
      # Capture the default source (microphone) as raw mono PCM @44.1 kHz and
      # stream it into the python pitch detector. On exit we kill python so
      # parec receives SIGPIPE and stops too — no lingering capture stream
      # (the Tuner widget only starts this while it is visible).
      set -u
      cleanup() { [ -n "''${pid:-}" ] && kill "$pid" 2>/dev/null; }
      trap cleanup INT TERM EXIT
      ${pkgs.pulseaudio}/bin/parec \
            --device=@DEFAULT_SOURCE@ \
            --rate=44100 --channels=2 --format=s16le --raw \
            --latency-msec=15 \
            2>/dev/null \
        | ${pkgs.python3.withPackages (ps: [ ps.numpy ])}/bin/python3 \
            "$HOME/.config/quickshell/tuner.py" &
      pid=$!
      wait "$pid"
    '';
    executable = true;
  };
  xdg.configFile."quickshell/nixos.svg".source =
    "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";

  # Theme.qml: the @PALETTE_ACCENT@ placeholder is seeded with the daemon's
  # default NixOS blue accent so the UI has a color before the daemon runs.
  # The user can still override it at runtime via Settings.
  xdg.configFile."quickshell/Theme.qml".text =
    builtins.replaceStrings [ "@PALETTE_ACCENT@" ] [ "#5277c3" ]
      (builtins.readFile "${src}/Theme.qml");

  xdg.configFile."quickshell/qmldir".source = "${src}/qmldir";

  # Note: Quickshell is started via Hyprland's exec-once (see home/modules/hyprland.nix)
  # No systemd service needed - that would run it twice!
}
