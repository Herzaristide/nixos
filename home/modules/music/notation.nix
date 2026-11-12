{ inputs, pkgs, ... }:

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
}
