{ config, pkgs, inputs, lib, ... }:

let
  # Initial wallpaper for DMS/DankGreeter (matugen generates colors from it)
  defaultWallpaper = ../src/wallpaper.jpg;
in
{
  options.theme = {
    initialWallpaper = lib.mkOption {
      type = lib.types.path;
      default = defaultWallpaper;
      description = "Initial wallpaper path for DMS and DankGreeter theming";
    };

    wallpaperFolder = lib.mkOption {
      type = lib.types.str;
      default = "wallpapers";
      example = "wallpapers";
      description = ''
        Wallpaper folder path relative to XDG data dir (~/.local/share).
        Wallpapers are stored in ~/.local/share/''${wallpaperFolder}/.
      '';
    };
  };

  config = { };
}
