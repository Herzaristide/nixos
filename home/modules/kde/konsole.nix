{ pkgs, ... }:

{
  home.packages = [ pkgs.kdePackages.konsole ];

  # Konsole profile — references the "Accent" colorscheme written by anna
  # at ~/.local/share/konsole/Accent.colorscheme on every accent change.
  xdg.dataFile."konsole/Accent.profile".text = ''
    [Appearance]
    ColorScheme=Accent
    Font=JetBrains Mono,11,-1,5,50,0,0,0,0,0

    [General]
    Name=Accent
    Parent=FALLBACK/
    TerminalMargin=16

    ErrorBars=0
    ErrorBackground=0
    AlternatingBars=0
    AlternatingBackground=0

    [Scrolling]
    HistoryMode=2
    HighlightScrolledLines=false

    [Terminal Features]
    BlinkingCursorEnabled=true
  '';

  xdg.configFile."konsolerc".text = ''
    [Desktop Entry]
    DefaultProfile=Accent.profile
  '';
}
