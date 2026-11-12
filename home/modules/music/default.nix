{ ... }:

# Musique : composer (Python), écouter et enregistrer (REAPER + instruments
# virtuels), graver (LilyPond), travailler (mpv). Chaîne :
#   music21 → MIDI → REAPER (rendu, prise de violon, mixage)
#           → LilyPond → conducteur + parties séparées
{
  imports = [
    ./composition.nix
    ./daw.nix
    ./instruments.nix
    ./notation.nix
    ./mpv.nix
  ];
}
