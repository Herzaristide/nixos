{ pkgs, ... }:

{
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "fcoeoabgfenejglbffodgkkbkcdhcgfn"; }
      { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; }
      { id = "effdbpeggelllpfkjppbokhmmiinhlmg"; }
      # React Developer Tools
      { id = "fmkadmapgofadopljbjfkapdkoienihi"; }
    ];
  };

  # ManagedBookmarks: home-manager n'expose pas `extraOpts`, donc on écrit
  # directement le fichier de policy par-utilisateur.
  xdg.configFile."chromium/policies/managed/preferences.json".text = builtins.toJSON {
    TranslateEnabled = false;
    # 2 = aucun site ne peut afficher de notifications (bloque les pubs push).
    DefaultNotificationsSetting = 2;
  };

  xdg.configFile."chromium/policies/managed/bookmarks.json".text = builtins.toJSON {
    ManagedBookmarks = [
      {
        name = "GitHub";
        url = "https://github.com";
      }
      {
        name = "Claude";
        url = "https://claude.ai";
      }
      {
        name = "Figma";
        url = "https://www.figma.com";
      }
    ];
  };

  # PWA launcher scripts. Chromium suit le color-scheme système via xdg-desktop-portal.
  home.packages = with pkgs; [
    (writeShellScriptBin "hypr-gemini-launch" "gemini-pwa")
    (writeShellScriptBin "gemini-pwa" "chromium --app=https://gemini.google.com --user-data-dir=$HOME/.config/chromium")
    (writeShellScriptBin "claude-pwa" "chromium --app=https://claude.ai --user-data-dir=$HOME/.config/chromium")
    (writeShellScriptBin "bandlab-pwa" "chromium --app=https://www.bandlab.com --user-data-dir=$HOME/.config/chromium")
    (writeShellScriptBin "deezer-pwa" "chromium --app=https://www.deezer.com --user-data-dir=$HOME/.config/chromium")
  ];

  xdg.desktopEntries.claude-chrome = {
    name = "Claude";
    comment = "Claude AI assistant in a Chromium PWA";
    exec = "claude-pwa";
    icon = "claude";
    categories = [ "Utility" ];
    startupNotify = true;
  };

  # BandLab PWA (music production web app)
  xdg.desktopEntries.bandlab-chrome = {
    name = "BandLab";
    comment = "Music production studio in your browser";
    exec = "bandlab-pwa";
    icon = "multimedia-audio-editor";
    categories = [
      "Audio"
      "AudioVideo"
    ];
    startupNotify = true;
  };

  # Deezer PWA
  xdg.desktopEntries.deezer-chrome = {
    name = "Deezer";
    comment = "Deezer music streaming in a Chromium PWA";
    exec = "deezer-pwa";
    icon = "deezer";
    categories = [
      "Audio"
      "AudioVideo"
    ];
    startupNotify = true;
  };
}
