{ lib, pkgs, ... }:

# Les visionneuses : une petite fenêtre flottante par type de fichier, dans
# l'esprit de f3d (f3d.nix) — on regarde, on écoute, on ferme. Les règles
# flottantes (taille, centrage) sont dans hyprland/hyprland.nix.
#
#   images      imv          (app_id « imv »)
#   audio       mpv          (app_id « mpv-audio », cf. l'entrée ci-dessous)
#   modèles 3D  f3d          (f3d.nix ; classe XWayland « Vtk »)
#   vidéo       mpv          (app_id « mpv », mpv.desktop)
#
# Le Markdown,
# le JSON et le CSV s'ouvrent dans Zed.
let
  images = [
    "image/png"
    "image/jpeg"
    "image/gif"
    "image/webp"
    "image/svg+xml"
    "image/avif"
    "image/heif"
    "image/heic"
    "image/jxl"
    "image/tiff"
    "image/bmp"
    "image/x-bmp"
    "image/x-portable-pixmap"
    "image/x-portable-graymap"
    "image/x-portable-bitmap"
    "image/x-portable-anymap"
    "image/qoi"
    "image/x-farbfeld"
  ];

  audio = [
    "audio/mpeg"
    "audio/mp3"
    "audio/flac"
    "audio/x-flac"
    "audio/ogg"
    "audio/x-vorbis+ogg"
    "audio/opus"
    "audio/x-opus+ogg"
    "audio/wav"
    "audio/x-wav"
    "audio/vnd.wave"
    "audio/aac"
    "audio/x-aac"
    "audio/mp4"
    "audio/x-m4a"
    "audio/webm"
    "audio/x-aiff"
    "audio/aiff"
    "audio/x-ape"
    "audio/x-wavpack"
    "audio/x-ms-wma"
    "audio/x-matroska"
  ];

  video = [
    "video/mp4"
    "video/x-matroska"
    "video/webm"
    "video/quicktime"
    "video/x-msvideo"
    "video/mpeg"
    "video/ogg"
    "video/x-flv"
  ];

  # Le texte structuré, dans Zed comme le reste du texte.
  text = [
    "text/markdown"
    "text/x-markdown"
    "application/json"
    "application/x-ndjson"
    "text/csv"
    "text/x-csv"
    "text/tab-separated-values"
  ];

  to = app: types: lib.genAttrs types (_: [ app ]);
in
{
  home.packages = [
    pkgs.imv
    # Les outils des aperçus de l'Explorer de karenine (anna/src/previews.rs),
    # aussi à la main : ffmpeg/ffprobe (images de vidéo, pochettes, waveforms),
    # pdftoppm (première page d'un PDF). anna embarque les siens ; f3d,
    # lilypond/musicxml2ly, unzip et bubblewrap viennent d'autres modules
    # (f3d.nix, music/notation.nix, modules/common.nix, code/ia/claude.nix).
    pkgs.ffmpeg
    pkgs.poppler-utils
  ];

  # L'audio dans mpv, mais en petit lecteur : une fenêtre même sans
  # pochette (pseudo-gui), la barre de lecture toujours visible, et son
  # propre app_id pour que Hyprland la mette en flottant, petite. Cachée
  # des lanceurs : on y arrive en ouvrant un fichier.
  xdg.desktopEntries.mpv-audio = {
    name = "mpv (audio)";
    genericName = "Lecteur audio";
    exec = "mpv --player-operation-mode=pseudo-gui --wayland-app-id=mpv-audio --force-window=immediate --script-opts=osc-visibility=always -- %U";
    icon = "mpv";
    terminal = false;
    noDisplay = true;
    categories = [
      "AudioVideo"
      "Audio"
      "Player"
    ];
    mimeType = audio;
  };

  xdg.mimeApps.defaultApplications =
    to "imv.desktop" images
    // to "mpv-audio.desktop" audio
    // to "mpv.desktop" video
    // to "dev.zed.Zed.desktop" text;
}
