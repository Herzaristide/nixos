{ pkgs, ... }:

{
  programs.chromium = {
    enable = true;
    extensions = [
      { id = "fcoeoabgfenejglbffodgkkbkcdhcgfn"; }
      { id = "ddkjiahejlhfcafbddmgiahcphecmpfh"; }
      { id = "effdbpeggelllpfkjppbokhmmiinhlmg"; }
    ];
  };

  # ManagedBookmarks: home-manager n'expose pas `extraOpts`, donc on écrit
  # directement le fichier de policy par-utilisateur.
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

  # PWA launcher scripts (per-host Chromium profile, forced dark mode)
  home.packages = with pkgs; [
    (writeShellScriptBin "hypr-claude-launch" "claude-pwa")
    (writeShellScriptBin "hypr-gemini-launch" "gemini-pwa")
    (writeShellScriptBin "gemini-pwa" "chromium --app=https://gemini.google.com --user-data-dir=$HOME/.config/chromium-$(hostname) --enable-features=WebUIDarkMode --force-dark-mode")
    (writeShellScriptBin "claude-pwa" "chromium --app=https://claude.ai --user-data-dir=$HOME/.config/chromium-$(hostname) --enable-features=WebUIDarkMode --force-dark-mode")
    (writeShellScriptBin "bandlab-pwa" "chromium --app=https://www.bandlab.com --user-data-dir=$HOME/.config/chromium-$(hostname) --enable-features=WebUIDarkMode --force-dark-mode")
  ];

  # Claude PWA (Claude.ai in app window, per-host Chromium profile)
  xdg.desktopEntries.claude-chrome = {
    name = "Claude";
    comment = "Anthropic Claude AI assistant";
    exec = "claude-pwa";
    icon = "applications-internet";
    categories = [ "Chat" ];
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
}
