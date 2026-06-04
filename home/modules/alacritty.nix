{ config, ... }:

{
  programs.alacritty = {
    enable = true;
    settings = {
      general.import = [
        "${config.home.homeDirectory}/.config/accent/fragments/alacritty-colors.toml"
      ];

      font = {
        size = 10.0;
        normal = {
          family = "JetBrains Mono";
          style = "Regular";
        };
      };

      window = {
        opacity = 1.0;
        decorations = "None";
        padding = {
          x = 16;
          y = 16;
        };
        dynamic_padding = false;
      };

      scrolling.history = 5000;

      selection.save_to_clipboard = true;

      cursor.style = {
        shape = "Beam";
        blinking = "On";
      };

      bell.duration = 0;

      terminal.shell.program = "fish";

      keyboard.bindings = [
        {
          key = "E";
          mods = "Alt";
          action = "CreateNewWindow";
        }
        {
          key = "T";
          mods = "Control|Shift";
          action = "SpawnNewInstance";
        }
      ];
    };
  };
}
