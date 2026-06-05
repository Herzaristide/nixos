{ pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    reaper
  ];

  # Avec xwayland.force_zero_scaling = true dans Hyprland, les apps XWayland voient
  # la résolution physique (ex: 1920×1080) au lieu de la résolution logique (1536×864).
  # uiscale=125 indique à Reaper d'agrandir son UI d'un facteur 1.25 pour compenser,
  # ce qui donne un rendu net à la taille attendue.
  # colorscheme sélectionne le thème sombre moderne livré avec Reaper.
  home.activation.reaperConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    _reaper_ini="$HOME/.config/REAPER/reaper.ini"
    mkdir -p "$HOME/.config/REAPER"

    if [ ! -f "$_reaper_ini" ]; then
      printf '[REAPER]\nuiscale=125\ncolorscheme=Default 6.0 (redux)\n' > "$_reaper_ini"
    else
      if ! grep -q '^\[REAPER\]' "$_reaper_ini"; then
        printf '\n[REAPER]\n' >> "$_reaper_ini"
      fi
      if ! grep -q '^uiscale=' "$_reaper_ini"; then
        sed -i '/^\[REAPER\]/a uiscale=125' "$_reaper_ini"
      fi
      if ! grep -q '^colorscheme=' "$_reaper_ini"; then
        sed -i '/^\[REAPER\]/a colorscheme=Default 6.0 (redux)' "$_reaper_ini"
      fi
    fi
  '';
}
