{ pkgs, ... }:

{
  # OBS Studio — enregistrement/streaming. Module headful (GUI).
  # La capture d'écran sous Hyprland passe par le portail PipeWire
  # (xdg-desktop-portal-hyprland), déjà présent via head.nix ; aucun plugin
  # de capture wlroots n'est donc nécessaire.
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      obs-pipewire-audio-capture # capture audio par application (PipeWire)
      obs-vaapi # encodage matériel VA-API (Intel iGPU / AMD)
    ];
  };
}
