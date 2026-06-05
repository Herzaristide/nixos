{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fluidsynth # GM MIDI software synthesizer
    soundfont-fluid # FluidR3 GM2 soundfont
    sfizz # SFZ sampler (LV2/JACK plugin)
  ];
}
