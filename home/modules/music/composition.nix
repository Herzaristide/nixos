{ pkgs, ... }:

# Composition et analyse en Python (music21, mido, librosa, reapy) : c'est par
# là que Claude écrit les arrangements et vérifie les prises. Environnement
# défini dans ./python-env.nix, partagé avec REAPER.
#
# basic-pitch (audio → MIDI, Spotify) n'est pas dans nixpkgs et tire
# TensorFlow/ONNX : le lancer à la demande, `uvx basic-pitch <sortie> <prise.wav>`
# (cache d'uv persisté).
{
  home.packages = [ (import ./python-env.nix pkgs) ];
}
