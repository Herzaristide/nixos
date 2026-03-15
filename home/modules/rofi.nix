{ config, pkgs, ... }:

{
  # Rofi launcher configuration
  home.packages = [
    pkgs.rofi
    pkgs.nerd-fonts.monoid
  ];

  xdg.configFile."rofi/config.rasi".text = ''
    configuration {
      display-drun: "Applications";
      display-window: "Windows";
      display-run: "Commands";
      modi: "window,drun,run";
      kb-mode-next: "Alt+l";
      kb-mode-previous: "Alt+h";
    }

    @theme "/dev/null"

    * {
      black:        #000000DD;
      White:        #FFFFFF;
      BrightRed:    #D90202;
      NeonPurple:   #932CB0;
      Cyan:         #33D4C4;
      Orange:       #B5340E;
      font: "MonoidNerdFont 15";

      background-color: transparent;
    }

    window {
      transparency: "real";
      background-color: @black;
      width: 50%;
      border: 3px;
      border-color: @BrightRed;
      border-radius: 30px;
    }

    mainbox {
      children: [inputbar, mode-switcher, listview];
      spacing: 20px;
      padding: 30px 0;
    }

    inputbar {
      padding: 0 30px;
      children: [prompt, textbox-prompt-colon, entry];
    }

    prompt {
      text-color: @BrightRed;
    }

    textbox-prompt-colon {
      expand: false;
      str: ":";
      padding: 0px 10px;
      text-color: @White;
    }

    entry {
      text-color: @Cyan;
      cursor-color: @Cyan;
      cursor-width: 10px;
    }

    mode-switcher {
      border: 2px 0;
      border-color: @BrightRed;
      background-color: #362921;
    }

    button {
      background-color: #000000;
      text-color: @Cyan;
      border-radius: 30px;
      margin: 0px 3px;
      padding: 5px;
    }

    button selected {
      background-color: @White;
      text-color: @BrightRed;
    }

    listview {
      scrollbar: true;
      margin: 0 0px 0 10px;
    }

    scrollbar {
      background-color: @White;
      handle-color: @BrightRed;
      handle-width: 15px;
      border-radius: 30px;
      margin: 0 0 0 10px;
    }

    element {
      margin: 8px 10px;
      padding: 0px 90px;
      spacing: 5px;
      children: [element-text];
    }

    element-text normal.normal {
      text-color: @Cyan;
      horizontal-align: 0.45;
    }

    element-text selected.normal {
      text-color: @BrightRed;
      background-color: @White;
      border-radius: 30px;
      horizontal-align: 0.45;
    }

    element-text alternate.normal {
      text-color: @Cyan;
      horizontal-align: 0.45;
    }
  '';
}
