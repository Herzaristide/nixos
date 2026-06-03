{
  config,
  lib,
  pkgs,
  darkMode ? true,
  ...
}:

let
  # Arcanum - Red icon theme by StormRosenaa (GPL-3.0)
  # https://codeberg.org/StormRosenaa/Arcanum
  arcanum-red-icons = pkgs.runCommand "arcanum-red-icons" { } ''
    mkdir -p "$out/share/icons"
    tar -xf ${
      pkgs.fetchurl {
        url = "https://codeberg.org/StormRosenaa/Arcanum/raw/branch/main/Arcanum%20-%20Red.tar.xz";
        name = "arcanum-red.tar.xz";
        hash = "sha256-3vZPao6T0saE5RiQGyYEZVts3FLZeGirRxU9hepSGgM=";
      }
    } -C "$out/share/icons"
  '';

  # Slot Plasma Themes — GPL-3.0 by L4ki
  # Only the GTK theme and icon themes are used here (Hyprland, not KDE Plasma).
  slot-src = pkgs.fetchFromGitHub {
    owner = "L4ki";
    repo = "Slot-Plasma-Themes";
    rev = "4dd93ad62cf47307d85e3a624eacba34578bf1fe";
    sha256 = "06pjizpkfd229mwa90a55888x15h5c9bvs59v12sh3ngyb4c4s1k";
  };

  slot-gtk-theme = pkgs.stdenv.mkDerivation {
    name = "slot-gtk-theme";
    src = slot-src;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/share/themes
      cp -r "Slot GTK Themes/Slot-Dark-GTK" $out/share/themes/Slot-Dark-GTK
    '';
  };

  # Activation script: set infoDock visibility byte to 0 (hidden) in the
  # Qt binary state blob.  Idempotent: exits early when already hidden.
  hideDolphinInfoScript = pkgs.writeText "hide-dolphin-info-panel.py" ''
    import base64, os, re, sys
    path = os.path.expanduser("~/.local/state/dolphinstaterc")
    if not os.path.exists(path):
        sys.exit(0)
    with open(path) as f:
        content = f.read()
    m = re.search(r"^State=(.+)$", content, re.MULTILINE)
    if not m:
        sys.exit(0)
    try:
        data = bytearray(base64.b64decode(m.group(1).strip()))
    except Exception:
        sys.exit(0)
    needle = "infoDock".encode("utf-16-be")
    idx = bytes(data).find(needle)
    if idx < 0:
        sys.exit(0)
    vis = idx + len(needle)
    if data[vis] == 0:
        sys.exit(0)  # already hidden
    data[vis] = 0
    new_b64 = base64.b64encode(bytes(data)).decode()
    new_content = re.sub(r"^State=.+$", "State=" + new_b64, content, flags=re.MULTILINE)
    with open(path, "w") as f:
        f.write(new_content)
  '';

in
{
  # GTK theme — Slot Dark (Hyprland-compatible GTK theme by L4ki)
  gtk = {
    enable = true;
    theme = {
      # Slot only ships a dark variant; fall back to Breeze for light mode.
      name = if darkMode then "Slot-Dark-GTK" else "Breeze";
      package = if darkMode then slot-gtk-theme else pkgs.kdePackages.breeze-gtk;
    };
    iconTheme = {
      # Arcanum-Accent is generated at activation time by paletted:
      # it copies all SVGs from "Arcanum - Red" and recolors #ff6666/#5a0d0d
      # to match the current accent hue. Falls back to "Arcanum - Red" via Inherits.
      name = "Arcanum-Accent";
      package = arcanum-red-icons; # installs the base theme used as source
    };
    font = {
      name = "JetBrains Mono";
      package = pkgs.jetbrains-mono;
      size = 11;
    };
    gtk3.extraConfig = {
      "gtk-application-prefer-dark-theme" = darkMode;
    };
    gtk4 = {
      theme = null;
      extraConfig = {
        "gtk-application-prefer-dark-theme" = darkMode;
      };
      # Pulls in the libadwaita color tokens fragment rewritten by paletted
      # on every accent change. The rest of the GTK4 config stays declarative.
      extraCss = ''
        @import url("file://${config.home.homeDirectory}/.config/accent/fragments/gtk4-colors.css");
      '';
    };
  };

  # Qt theming — Breeze (consistent with KDE apps like Dolphin)
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style = {
      name = "breeze";
      package = pkgs.kdePackages.breeze;
    };
  };

  # Icon themes — symlinked into ~/.local/share/icons/ so both GTK and Qt/KDE
  # find them without any cache generation step.
  xdg.dataFile."icons/Arcanum - Red" = {
    source = "${arcanum-red-icons}/share/icons/Arcanum - Red";
    force = true;
  };

  home.packages = with pkgs; [
    kdePackages.ark
    kdePackages.konsole
  ];

  # Konsole profile — references the "Accent" colorscheme written by paletted
  # at ~/.local/share/konsole/Accent.colorscheme on every accent change.
  xdg.dataFile."konsole/Accent.profile".text = ''
    [Appearance]
    ColorScheme=Accent
    Font=JetBrains Mono,11,-1,5,50,0,0,0,0,0

    [General]
    Name=Accent
    Parent=FALLBACK/

    [Scrolling]
    HistoryMode=2

    [Terminal Features]
    BlinkingCursorEnabled=true
  '';

  xdg.configFile."konsolerc".text = ''
    [Desktop Entry]
    DefaultProfile=Accent.profile
  '';

  # Dolphin — file manager. Most of dolphinrc is plain INI and lives here.
  # Dock-widget layout (Konsole panel position, sizes) is stored separately
  # in ~/.local/state/dolphinstaterc as Qt's opaque saveState() blob, which
  # is kept mutable so the panel can be repositioned by drag at runtime.
  xdg.configFile."dolphinrc".force = true;
  xdg.configFile."dolphinrc".text = ''
    [General]
    BrowseThroughArchives=true
    GlobalViewProps=true
    OpenExternallyCalledFolderInNewTab=true
    RememberOpenedTabs=false
    ShowFullPath=true
    ShowFullPathInTitlebar=true
    ShowSpaceInfo=true
    ShowStatusBar=FullWidth
    Version=202

    [DetailsMode]
    PreviewSize=22
    SidePadding=2

    [IconsMode]
    PreviewSize=64

    [PreviewSettings]
    Plugins=appimagethumbnail,audiothumbnail,blenderthumbnail,comicbookthumbnail,cursorthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,directorythumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,windowsexethumbnail,windowsimagethumbnail,opendocumentthumbnail,gsthumbnail,rawthumbnail,svgthumbnail,textthumbnail,ffmpegthumbs

    [VersionControl]
    enabledPlugins=Git

    [Search]
    Location=Everywhere

    [KFileDialog Settings]
    Places Icons Auto-resize=false
    Places Icons Static Size=22

    [MainWindow]
    MenuBar=Disabled
    ToolBarsMovable=Disabled

    [MainWindow][Toolbar mainToolBar]
    Hidden=true
    ToolButtonStyle=IconOnly

    [PlacesPanel]
    PanelFontSize=10

    [ContentDisplay]
    UsePermissionsFormat=PermissionsFormatCombined

    [FoldersPanel]
    LimitFoldersPanelToHome=false
  '';

  # Patch the Qt binary state blob on every rebuild so the information panel
  # starts hidden.  The file remains mutable at runtime (drag/resize still work).
  home.activation.hideDolphinInfoPanel = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.python3}/bin/python3 ${hideDolphinInfoScript}
  '';

}
