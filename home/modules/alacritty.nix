{ config, pkgs, ... }:

let
  home = config.home.homeDirectory;
in
{
  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
    # Base TOML config. The accent-colors file is imported last so it wins.
    # Alacritty watches all imported files and hot-reloads automatically —
    # accent-sync just needs to write ~/.config/alacritty/accent-colors.toml.
    settings = {
      # ── font ───────────────────────────────────────────────────────────
      font = {
        normal = {
          family = "JetBrains Mono";
          style = "Regular";
        };
        bold = {
          family = "JetBrains Mono";
          style = "Bold";
        };
        italic = {
          family = "JetBrains Mono";
          style = "Italic";
        };
        size = 10.0;
      };

      # ── window ─────────────────────────────────────────────────────────
      window = {
        opacity = 0.0;
        decorations = "None";
        padding = {
          x = 16;
          y = 16;
        };
        dynamic_padding = false;
      };

      # ── scrolling ──────────────────────────────────────────────────────
      scrolling.history = 5000;

      # ── bell ───────────────────────────────────────────────────────────
      bell.animation = "Linear";
      bell.duration = 0;

      # ── shell ──────────────────────────────────────────────────────────
      terminal.shell = {
        program = "fish";
      };

      # ── cursor ─────────────────────────────────────────────────────────
      cursor = {
        style = {
          shape = "Beam";
          blinking = "Always";
        };
      };

      # ── colors ──────────────────────────────────────────────────────────
      # All color definitions live in accent-colors.toml (written by accent-sync).
      # Alacritty imports are loaded BEFORE the main file, so defining any
      # [colors.*] table here would replace the imported table entirely.

      # ── keybinds ───────────────────────────────────────────────────────
      keyboard.bindings = [
        # splits (use tmux-style prefix because alacritty has no built-in splits)
        # new tab
        {
          key = "T";
          mods = "Control|Shift";
          action = "CreateNewTab";
        }
      ];

      # ── import accent override (written by accent-sync, auto-reloaded) ──
      # Alacritty watches all imported files for changes; no signal needed.
      # The file is silently skipped if missing (first boot before accentSeed).
      general.import = [
        "${home}/.config/alacritty/accent-colors.toml"
      ];
    };
  };
}
