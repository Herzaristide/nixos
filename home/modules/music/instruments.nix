{ pkgs, ... }:

# Instruments virtuels : les lecteurs (samplers) sont des paquets, les banques
# de sons non. Ce sont des données (plusieurs Go) à déposer à la main :
#   - SFZ (sfizz) dans ~/.local/share/sfz/ — VSCO 2 Community Edition,
#     Virtual Playing Orchestra, Salamander Grand Piano…
#   - Decent Sampler : banques Pianobook (.dspreset), même dossier conseillé.
# ~/.local/share/sfz est persisté (modules/impermanence.nix).
{
  home.packages = with pkgs; [
    fluidsynth # synthé General MIDI logiciel (écoute rapide d'un .mid)
    soundfont-fluid # soundfont FluidR3 GM2
    sfizz # lecteur SFZ (LV2/VST3, et `sfizz_render` pour rendre un MIDI en WAV)
    decent-sampler # lecteur des banques Pianobook (unfree)
  ];
}
