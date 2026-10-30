[
  # Les deux écrans du bureau se branchent soit sur gary, soit sur bernanos : on les
  # désigne par leur description EDID (`desc:`), identique sur les deux hôtes,
  # et non par le nom du connecteur, qui en dépend (HP = DP-4 sur gary, DP-3 sur
  # bernanos ; Samsung = HDMI-A-3 sur gary, HDMI-A-1 sur bernanos).
  #
  # HP E24q G5, posé au-dessus du Samsung, retourné 180° (transform 2).
  {
    output = "desc:HP Inc. HP E24q G5 CNC3021TQS";
    mode = "2560x1440@75";
    position = "0x0";
    scale = 1.60;
    transform = 2;
  }
  # Samsung C27R50x, écran principal sous le HP.
  {
    output = "desc:Samsung Electric Company C27R50x H9JTB00510";
    mode = "1920x1080@60";
    position = "0x900";
    scale = 1.25;
  }
  # bernanos et exupery — écran intégré
  {
    output = "eDP-1";
    mode = "preferred";
    # Sous le Samsung, aligné sur son bord gauche (Samsung : 1536 × 864 px
    # logiques à y = 900, donc bord bas à 1764). Seul, sans les écrans du
    # bureau, la position est sans effet.
    position = "0x1764";
    scale = 1.25;
  }
  {
    output = "";
    mode = "preferred";
    position = "auto";
    scale = 1.25;
  }
]
