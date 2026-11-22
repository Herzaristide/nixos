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
  #
  # Toujours avec --no-cache : f3d retient sinon la taille et la position de
  # sa fenêtre (~/.cache/f3d/cache.json) et les restaure à l'ouverture,
  # par-dessus la règle flottante de Hyprland. Ces coordonnées X11, relues à
  # travers XWayland (force_zero_scaling, écrans à l'échelle 1,25 qui ne
  # partent pas de 0,0), tombent hors des écrans : la fenêtre s'ouvrait là,
  # invisible, et y était réenregistrée à chaque fermeture.
  home.packages = [
    (pkgs.symlinkJoin {
      name = "f3d-${pkgs.f3d.version}";
      paths = [ pkgs.f3d ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = "wrapProgram $out/bin/f3d --add-flags --no-cache";
    })
  ];

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
