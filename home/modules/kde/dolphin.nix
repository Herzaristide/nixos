{
  lib,
  pkgs,
  ...
}:

let
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
  home.packages = [ pkgs.kdePackages.dolphin ];

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
    Plugins=appimagethumbnail,audiothumbnail,blenderthumbnail,comicbookthumbnail,cursorthumbnail,djvuthumbnail,ebookthumbnail,exrthumbnail,fontthumbnail,imagethumbnail,jpegthumbnail,kraorathumbnail,windowsexethumbnail,windowsimagethumbnail,opendocumentthumbnail,gsthumbnail,rawthumbnail,svgthumbnail,textthumbnail,ffmpegthumbs

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
