{ pkgs, ... }:

{
  # tofi a no include mechanism — sa config complète est rendue par paletted
  # depuis ~/.config/accent/templates/tofi.config.tmpl vers ~/.config/tofi/config
  # sur chaque changement d'accent. Voir home/modules/accent/.
  home.packages = [ pkgs.tofi ];
}
