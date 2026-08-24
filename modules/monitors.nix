[
  # gary — HP E24q G5, posé au-dessus du Samsung (HDMI-A-3), retourné 180° (transform 2).
  {
    output = "DP-4";
    mode = "2560x1440@75";
    position = "0x0";
    scale = 1.60;
    transform = 2;
  }
  # gary — Samsung C27R50x, écran principal sous DP-4.
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
