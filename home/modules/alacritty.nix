{ config, pkgs, ... }:

let
  shortcuts = import ./shortcuts.nix { inherit pkgs; };
in
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

      # Raccourcis définis dans home/modules/shortcuts.nix (source de vérité
      # partagée avec Hyprland/zellij/Zed/micro).
      keyboard.bindings = map (
        {
          key,
          mods,
          action,
          ...
        }:
        {
          inherit key mods action;
        }
      ) shortcuts.alacritty;
    };
  };
}
