# Environnement Python de la musique, partagé par ./composition.nix (dans le
# PATH : composer, analyser, convertir) et ./daw.nix (PYTHONPATH du Python
# embarqué de REAPER, pour que reapy y soit importable). Un seul environnement,
# donc une seule version de reapy des deux côtés.
pkgs:

let
  python = pkgs.python3;
  music21 = python.pkgs.callPackage ./pkgs/music21.nix { };
  python-reapy = python.pkgs.callPackage ./pkgs/python-reapy.nix { };
in
python.withPackages (ps: [
  music21 # composition symbolique → MusicXML / MIDI / LilyPond
  python-reapy # pilotage de REAPER
  ps.mido # lecture/écriture MIDI bas niveau
  ps.librosa # analyse audio des prises (justesse, tempo, attaques)
])
