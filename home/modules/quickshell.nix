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
  # panels/ widgets/ ai/ assets/ + un qmldir par dossier). Ce paquet est la
  # seule source de vérité de la structure ; on n'y superpose ci-dessous que ce
  # qui est spécifique à la machine.
  #
  # Les anciens backends audio (tuner/chroma/mic-level en Python+parec) ont été
  # absorbés par le daemon Rust `anna` : les widgets s'abonnent désormais à ses
  # services via le socket Unix (`tuner_watch`, `chroma_watch`, `hwstats_watch`),
  # donc plus aucun wrapper shell ni dossier `backend/` à superposer ici.
  karenine = inputs.karenine.packages.${system}.default;

  nixSnowflake = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake-white.svg";

  # Layout final = paquet karenine + superpositions machine.
  configured = pkgs.runCommand "karenine-configured" { } ''
    cp -r ${karenine} "$out"
    chmod -R u+w "$out"

    # Écran de la barre (le paquet code "DP-1" en dur pour l'usage standalone).
    substituteInPlace "$out/shell.qml" \
      --replace-warn 'primaryScreen: "DP-1"' 'primaryScreen: "${primaryMonitor}"'

    # Icône NixOS épinglée depuis nixpkgs.
    cp ${nixSnowflake} "$out/assets/nixos.svg"
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
