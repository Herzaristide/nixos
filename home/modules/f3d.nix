{ pkgs, ... }:

{
  # Visionneuse 3D légère : sert à regarder les modèles générés par IA
  # (TRELLIS.2 dans ComfyUI sur gary, .glb texturés). Remplace Blender
  # (2026-11-17), qui ne servait qu'à ça.
  #
  # Le paquet apporte ses thumbnailers (share/thumbnailers), que Nautilus
  # trouve via le profil home-manager : miniatures des .glb/.gltf/.obj/.stl…
  # Sans fenêtre, `f3d model.glb --output render.png --resolution 800,800`
  # produit une image — de quoi vérifier un mesh depuis Claude Code.
  home.packages = [ pkgs.f3d ];

  xdg.mimeApps.defaultApplications = {
    "model/gltf-binary" = [ "f3d.desktop" ];
    "model/gltf+json" = [ "f3d.desktop" ];
    "model/obj" = [ "f3d.desktop" ];
    "model/stl" = [ "f3d.desktop" ];
    "model/x.stl-binary" = [ "f3d.desktop" ];
    "model/x.stl-ascii" = [ "f3d.desktop" ];
    "model/vnd.usdz+zip" = [ "f3d.desktop" ];
    "model/x-ply" = [ "f3d.desktop" ];
    "application/x-fbx" = [ "f3d.desktop" ];
  };
}
