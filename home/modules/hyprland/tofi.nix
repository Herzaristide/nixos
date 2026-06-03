{ pkgs, ... }:

{
  home.packages = [ pkgs.tofi ];

  xdg.configFile."tofi/config".text = ''
    font = JetBrains Mono
    font-size = 14

    width = 800
    height = fit-content
    horizontal = false
    num-results = 8

    # Colours
    background-color           = #00000000
    text-color                 = #33D4C4
    prompt-color               = #D90202
    selection-color            = #D90202
    selection-background-color = #ffffff

    border-width  = 0
    outline-width = 0

    padding-top    = 12
    padding-bottom = 12
    padding-left   = 30
    padding-right  = 30
    result-spacing = 8

    anchor          = center
    exclusive-zone  = -1
    margin-top      = 0
    margin-right    = 0
    margin-bottom   = 0
    margin-left     = 0

    output          =
  '';
}
