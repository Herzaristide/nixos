{
  config,
  pkgs,
  lib,
  ...
}:

let
  # Script pour gérer le parallax wallpaper avec swww
  swww-parallax = pkgs.writeShellScriptBin "swww-parallax" ''
    #!/usr/bin/env bash

    WALLPAPER="/etc/nixos/src/wallpaper.jpg"
    CACHE_DIR="$HOME/.cache/swww-parallax"

    # Dimensions de l'écran (ajuster selon ta résolution)
    SCREEN_WIDTH=1920
    SCREEN_HEIGHT=1080

    # Dimensions du wallpaper ultra-large (9076x4097)
    WALLPAPER_WIDTH=9076

    # Nombre de workspaces
    NUM_WORKSPACES=5

    # Calculer le décalage par workspace
    OFFSET_PER_WS=$(( (WALLPAPER_WIDTH - SCREEN_WIDTH) / (NUM_WORKSPACES - 1) ))

    # Créer le répertoire cache si nécessaire
    mkdir -p "$CACHE_DIR"

    # Pré-générer les 5 crops du wallpaper (une fois au démarrage)
    generate_crops() {
      echo "Génération des crops du wallpaper parallax..."
      for ws in {1..5}; do
        local offset=$(( (ws - 1) * OFFSET_PER_WS ))
        local output="$CACHE_DIR/wallpaper_ws$ws.jpg"

        # Utiliser ImageMagick pour cropper le wallpaper
        # -crop WIDTHxHEIGHT+XOFFSET+YOFFSET
        ${pkgs.imagemagick}/bin/convert "$WALLPAPER" \
          -crop "''${SCREEN_WIDTH}x''${SCREEN_HEIGHT}+''${offset}+0" \
          +repage \
          "$output"
      done
      echo "Crops générés dans $CACHE_DIR"
    }

    # Fonction pour appliquer le wallpaper selon le workspace
    apply_wallpaper() {
      local workspace=$1
      local monitor=$2

      # Limiter aux workspaces 1-5
      if [ "$workspace" -ge 1 ] && [ "$workspace" -le "$NUM_WORKSPACES" ]; then
        local wallpaper_file="$CACHE_DIR/wallpaper_ws$workspace.jpg"

        if [ -f "$wallpaper_file" ]; then
          # Appliquer avec swww
          # --transition-type=wipe avec --transition-angle pour slide horizontal
          # --transition-step=255 pour transition rapide
          ${pkgs.swww}/bin/swww img "$wallpaper_file" \
            --transition-type=wipe \
            --transition-angle=270 \
            --transition-step=90 \
            --transition-fps=60 \
            --outputs "$monitor"
        fi
      fi
    }

    # Écouter les événements Hyprland pour les changements de workspace
    handle_event() {
      while IFS= read -r line; do
        # Format: workspace>>WORKSPACE_ID
        if [[ "$line" =~ ^workspace\>\>([0-9]+)$ ]]; then
          workspace_id="''${BASH_REMATCH[1]}"

          # Appliquer le wallpaper pour le workspace actif sur chaque moniteur
          for monitor in $(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[].name'); do
            apply_wallpaper "$workspace_id" "$monitor"
          done
        fi
      done
    }

    # Lancer swww daemon si pas déjà lancé
    if ! pgrep -x swww-daemon > /dev/null; then
      ${pkgs.swww}/bin/swww-daemon &
      sleep 1
    fi

    # Générer les crops si le cache n'existe pas ou si le wallpaper a changé
    if [ ! -f "$CACHE_DIR/wallpaper_ws1.jpg" ] || \
       [ "$WALLPAPER" -nt "$CACHE_DIR/wallpaper_ws1.jpg" ]; then
      generate_crops
    fi

    # Initialiser le wallpaper sur workspace 1
    for monitor in $(hyprctl monitors -j | ${pkgs.jq}/bin/jq -r '.[].name'); do
      apply_wallpaper 1 "$monitor"
    done

    # Écouter les événements Hyprland
    ${pkgs.socat}/bin/socat -U - UNIX-CONNECT:"$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock" | handle_event
  '';
in
{
  home.packages = with pkgs; [
    swww
    socat
    jq
    imagemagick
    swww-parallax
  ];

  # Note: Le script sera lancé via exec-once dans hyprland.nix
}
