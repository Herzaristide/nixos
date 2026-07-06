{ pkgs, ... }:

let
  salamander = pkgs.callPackage ../../../pkgs/salamander-grand-piano { };
in
{
  home.packages = with pkgs; [
    fluidsynth # GM MIDI software synthesizer
    soundfont-fluid # FluidR3 GM2 soundfont
    sfizz # SFZ sampler (LV2/JACK plugin)
    salamander # Salamander Grand Piano V3 (SFZ)
  ];

  # Lien stable vers la banque pour que sfizz/REAPER la retrouvent sans aller
  # fouiller dans /nix/store.
  xdg.dataFile."sfz/SalamanderGrandPiano".source = "${salamander}/share/sfz/SalamanderGrandPiano";
}
