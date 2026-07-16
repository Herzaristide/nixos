# Description des moniteurs, partagée entre la session Hyprland de l'utilisateur
# (home/modules/hyprland/hyprland.nix) et le compositeur du greeter
# (modules/greetd.nix), pour que l'écran de login ait la même géométrie (et
# surtout les mêmes rotations) que la session.
#
# Chaque hôte ne reconnaît que ses propres sorties ; les autres lignes sont
# ignorées par Hyprland. La dernière entrée (output vide) est le fallback.
[
  # gary — HP E24q G5, posé au-dessus du Samsung (HDMI-A-3), retourné 180° (transform 2).
  # Branché sur l'iGPU (Raphael) → sort en DP-4 (au lieu de DP-2 sur le dGPU).
  {
    output = "DP-4";
    mode = "2560x1440@75";
    position = "0x0";
    scale = 1.60;
    transform = 2;
  }
  # gary — Samsung C27R50x, écran principal sous DP-4.
  # Branché sur l'iGPU (Raphael) → sort en HDMI-A-3 (au lieu de DP-1 sur le dGPU).
  {
    output = "HDMI-A-3";
    mode = "1920x1080@60";
    position = "0x900";
    scale = 1.25;
  }
  # zola — moniteur externe optionnel
  {
    output = "HDMI-A-1";
    mode = "1920x1080@60";
    position = "49x900";
    scale = 1.25;
  }
  # zola — écran intégré
  {
    output = "eDP-1";
    mode = "preferred";
    position = "auto-left";
    scale = 1.25;
  }
  {
    output = "";
    mode = "preferred";
    position = "auto";
    scale = 1.25;
  }
]
