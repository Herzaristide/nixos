{ config, ... }:

{
  # Config statique gérée déclarativement par home-manager.  Les couleurs
  # vivent dans un fragment écrit par paletted sous
  # ~/.config/accent/fragments/alacritty-colors.toml, importé via la
  # directive `general.import` d'Alacritty (qui surveille les fichiers
  # importés et auto-reload sur changement).
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
          key = "Q";
          mods = "Alt";
          action = "Quit";
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
