{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fluidsynth # GM MIDI software synthesizer
    soundfont-fluid # FluidR3 GM2 soundfont
    sfizz # SFZ sampler (LV2/JACK plugin)
  ];

  # Les banques SFZ (Salamander Grand Piano, …) ne sont plus gérées par Nix :
  # ce sont des données, pas des paquets. Les déposer à la main dans
  # ~/.local/share/sfz/, où sfizz et REAPER vont les chercher.
}
