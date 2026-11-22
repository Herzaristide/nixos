{
  inputs,
  lib,
  pkgs,
  ...
}:

# Partitions : LilyPond seul (pas de MuseScore). music21 (./composition.nix)
# exporte directement en LilyPond ; conducteur et parties séparées se gravent
# depuis le même source.
{
  # Vinteuil — pupitre zen pour les partitions LilyPond
  # (github:Herzaristide/vinteuil). Le binaire vient du cache Cachix rempli par
  # sa CI ; voir l'entrée `vinteuil` de flake.nix.
  imports = [ inputs.vinteuil.homeManagerModules.default ];

  programs.vinteuil.enable = true;

  home.packages = [ pkgs.lilypond ];

  # Vinteuil par défaut pour tout ce qu'il sait ouvrir. Son .desktop les
  # déclare, mais sans épinglage le choix ne tient qu'à l'absence d'une autre
  # appli candidate. Le MIDI garde FluidSynth (home/head.nix) en second, pour
  # « Ouvrir avec ».
  xdg.mimeApps.defaultApplications =
    lib.genAttrs [
      "text/x-lilypond"
      "application/vnd.recordare.musicxml+xml"
      "application/vnd.recordare.musicxml"
      "text/vnd.abc"
    ] (_: [ "vinteuil.desktop" ])
    //
      lib.genAttrs
        [
          "audio/midi"
          "audio/x-midi"
        ]
        (_: [
          "vinteuil.desktop"
          "fluidsynth.desktop"
        ]);
}
