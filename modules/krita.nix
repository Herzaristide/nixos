# Krita et son extension Krita AI Diffusion (bernanos). L'extension ne fait
# tourner aucun modèle ici : elle se branche sur le serveur ComfyUI de gary
# (modules/comfyui.nix), de la même release (pkgs/comfyui/krita-ai-diffusion.nix).
#
# Côté Nix on ne fait que déposer l'extension dans pykrita/. Une fois, à la
# main (l'état reste dans les fichiers persistés plus bas) :
#   1. Krita → Settings → Configure Krita → Python Plugin Manager : cocher
#      « AI Image Diffusion », puis relancer Krita ;
#   2. Settings → Dockers → AI Image Generation, puis ⚙ → Connection :
#      « Custom Server », adresse `http://gary:8188` (gary démarré avec
#      `sudo systemctl start comfyui`).
{ pkgs, ... }:

let
  release = import ../pkgs/comfyui/krita-ai-diffusion.nix;

  plugin = pkgs.fetchzip {
    inherit (release) url hash;
    stripRoot = false;
  };
in
{
  home-manager.users.aristide = {
    home.packages = [ pkgs.krita ];

    xdg.dataFile."krita/pykrita/ai_diffusion".source = "${plugin}/ai_diffusion";
    xdg.dataFile."krita/pykrita/ai_diffusion.desktop".source = "${plugin}/ai_diffusion.desktop";
  };

  environment.persistence."/keep".users.aristide = {
    # Réglages de Krita, dont l'extension activée. Fichier isolé : le reste de
    # ~/.config ne suit pas.
    files = [ ".config/kritarc" ];
    # Ressources de Krita (pinceaux, palettes…) et, sous ai_diffusion/, les
    # réglages de l'extension (serveur choisi, styles) et ses journaux. Les
    # liens pykrita/ posés par home-manager y sont refaits à chaque activation.
    directories = [ ".local/share/krita" ];
  };
}
