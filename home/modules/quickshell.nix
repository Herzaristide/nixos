{
  config,
  pkgs,
  lib,
  inputs,
  primaryMonitor ? "HDMI-A-1",
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;

  # Interface Quickshell (QML/scripts/assets) — dépôt séparé, tiré comme input
  # de flake. Depuis la restructuration, karenine expose `packages.default` :
  # un layout ~/.config/quickshell prêt à l'emploi (sous-dossiers services/
  # panels/ widgets/ ai/ backend/ assets/ + un qmldir par dossier). Ce paquet
  # est la seule source de vérité de la structure ; on n'y superpose ci-dessous
  # que ce qui est spécifique à la machine.
  karenine = inputs.karenine.packages.${system}.default;

  pythonNp = pkgs.python3.withPackages (ps: [ ps.numpy ]);
  parec = "${pkgs.pulseaudio}/bin/parec";
  pactl = "${pkgs.pulseaudio}/bin/pactl";

  # ── Wrappers backend spécifiques à la machine ────────────────────────────
  # karenine fournit des wrappers portables (parec|python via PATH, micro par
  # défaut). Sous NixOS on les remplace pour épingler parec / python+numpy
  # depuis le store et choisir les bons périphériques audio. Les scripts .py
  # (logique numpy) restent ceux du paquet.

  tunerSh = pkgs.writeShellScript "tuner.sh" ''
    # Capture le micro par défaut en PCM stéréo 44,1 kHz → détecteur de pitch.
    # À la sortie on tue python pour que parec reçoive SIGPIPE et s'arrête aussi.
    set -u
    cleanup() { [ -n "''${pid:-}" ] && kill "$pid" 2>/dev/null; }
    trap cleanup INT TERM EXIT
    ${parec} \
          --device=@DEFAULT_SOURCE@ \
          --rate=44100 --channels=2 --format=s16le --raw \
          --latency-msec=15 \
          2>/dev/null \
      | ${pythonNp}/bin/python3 -u ${karenine}/backend/tuner.py &
    pid=$!
    wait "$pid"
  '';

  chromaSh = pkgs.writeShellScript "chroma-analyzer.sh" ''
    # Capture le monitor du sink par défaut (ce que joue le système) en PCM
    # mono 22,05 kHz → analyseur de chromagramme.
    set -u
    SINK="$(${pactl} get-default-sink 2>/dev/null)"
    if [ -z "$SINK" ]; then
      echo "STATUS:READY"
      exec sleep infinity
    fi
    exec ${parec} \
          --device="''${SINK}.monitor" \
          --rate=22050 --channels=1 --format=s16le --raw \
          2>/dev/null \
      | ${pythonNp}/bin/python3 -u ${karenine}/backend/chroma-analyzer.py
  '';

  micLevelSh = pkgs.writeShellScript "mic-level.sh" ''
    # Épingle parec/python puis délègue au script mic-level du paquet
    # (sa logique RMS inline n'a pas besoin de numpy).
    export PAREC_BIN="${parec}"
    export PYTHON_BIN="${pkgs.python3}/bin/python3"
    exec bash ${karenine}/backend/mic-level.sh
  '';

  nixSnowflake = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";

  # Layout final = paquet karenine + superpositions machine.
  configured = pkgs.runCommand "karenine-configured" { } ''
    cp -r ${karenine} "$out"
    chmod -R u+w "$out"

    # Écran de la barre (le paquet code "DP-1" en dur pour l'usage standalone).
    substituteInPlace "$out/shell.qml" \
      --replace 'primaryScreen: "DP-1"' 'primaryScreen: "${primaryMonitor}"'

    # Wrappers backend épinglés au store + icône NixOS de nixpkgs.
    cp ${tunerSh}    "$out/backend/tuner.sh"
    cp ${chromaSh}   "$out/backend/chroma-analyzer.sh"
    cp ${micLevelSh} "$out/backend/mic-level.sh"
    cp ${nixSnowflake} "$out/assets/nixos.svg"
    chmod +x "$out"/backend/*.sh
  '';
in
{
  # NB: pas de python3 sur le PATH — les wrappers ci-dessus référencent leur
  # propre env python (avec numpy) via chemin absolu du store.
  home.packages = with pkgs; [
    inputs.quickshell.packages.${system}.default
    cava # source du spectre audio pour les barres EQ du widget musique
    pulseaudio # fournit parec/pactl
  ];

  # Un seul symlink : ~/.config/quickshell → layout assemblé (lecture seule).
  # L'état runtime (state.json du daemon anna) vit ailleurs
  # (~/.config/accent/state.json), donc le dossier n'a pas besoin d'être writable.
  xdg.configFile."quickshell".source = configured;

  # Note: Quickshell est lancé via l'exec-once de Hyprland (voir hyprland.nix).
}
