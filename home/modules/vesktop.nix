{ pkgs, ... }:

let
  # Le client web de Discord n'annonce au serveur vocal qu'UNE adresse locale,
  # prise parmi les candidats ICE de toutes les interfaces. Quand il prend celle
  # de tailscale0 (100.x / fd7a:…), le serveur répond dans le vide et l'appel
  # reste bloqué sur « DTLS connecting ». Ce flag Chromium limite WebRTC à
  # l'interface de la route par défaut. L'entrée .desktop lance `vesktop` via le
  # PATH, donc elle passe aussi par ce wrapper.
  vesktop = pkgs.symlinkJoin {
    name = "vesktop-${pkgs.vesktop.version}";
    paths = [ pkgs.vesktop ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/vesktop \
        --add-flags "--force-webrtc-ip-handling-policy=default_public_interface_only"
    '';
  };
in
{
  # Vesktop (Vencord) à la place du client Discord officiel : il partage l'écran
  # via le WebRTC standard de Chromium + xdg-desktop-portal (son compris, via
  # venmic), là où le moteur vidéo natif de Discord (encodage NVENC) faisait
  # planter son processus GPU sur zola et bloquait xdg-desktop-portal-hyprland.
  # Le thème est fourni par anna (quickCss.css, cf. modules/accent/accent.nix).
  home.packages = [ vesktop ];
}
