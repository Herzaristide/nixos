{ pkgs, ... }:

let
  # Chemin du logo résolu à l'évaluation Nix (store path littéral).
  #
  # `builtins.path` (et pas `toString ../../../src/nixos_logo.txt`) : ce dernier
  # pointait à l'intérieur de l'arbre source du flake, dont le hash change à
  # chaque modification du dépôt — n'importe quel commit sans rapport faisait
  # donc muter le chemin du logo, et avec lui les configs fastfetch générées.
  # Ici le fichier est importé seul : son store path ne dépend que de son
  # contenu, et reste stable tant que le logo lui-même ne change pas.
  logoPath = builtins.path {
    path = ../../../src/nixos_logo.txt;
    name = "nixos_logo.txt";
  };

  fastfetchSchema = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

  # Code ANSI 31 = red ; remappé vers l'accent par alacritty (slot 1, partagé
  # avec Claude Code en thème `dark-ansi`).
  ansiAccent = "31";

  # `nf` choisit la config compacte (logo seul) ou complète selon la largeur du terminal.
  nf = pkgs.writeShellScriptBin "nf" ''
    CFG_DIR="$HOME/.config/fastfetch"
    CFG_FULL="$CFG_DIR/full.jsonc"
    CFG_LOGO="$CFG_DIR/logo.jsonc"

    COLS=$(${pkgs.ncurses}/bin/tput cols 2>/dev/null || echo 80)

    if [ "$COLS" -lt 80 ]; then
      exec ${pkgs.fastfetch}/bin/fastfetch --config "$CFG_LOGO" "$@"
    else
      exec ${pkgs.fastfetch}/bin/fastfetch --config "$CFG_FULL" "$@"
    fi
  '';
in
{
  home.packages = [
    pkgs.fastfetch
    nf
  ];

  # ~/.config/fastfetch/full.jsonc
  xdg.configFile."fastfetch/full.jsonc".text = builtins.toJSON {
    "$schema" = fastfetchSchema;
    logo = {
      source = logoPath;
      color = {
        "1" = ansiAccent;
      };
      padding = {
        top = 1;
        right = 2;
      };
    };
    display = {
      separator = "  ";
      color = {
        keys = ansiAccent;
      };
      key = {
        width = 3;
      };
    };
    modules = [
      { type = "break"; }
      { type = "break"; }
      { type = "break"; }
      {
        type = "title";
        color = {
          user = ansiAccent;
          at = ansiAccent;
          host = ansiAccent;
        };
      }
      { type = "break"; }
      {
        type = "os";
        key = "◆ ";
        keyColor = ansiAccent;
      }
      {
        type = "kernel";
        key = "◆ ";
        keyColor = ansiAccent;
      }
      {
        type = "cpu";
        key = "◆ ";
        keyColor = ansiAccent;
      }
      {
        type = "gpu";
        key = "◆ ";
        keyColor = ansiAccent;
      }
      {
        type = "memory";
        key = "◆ ";
        keyColor = ansiAccent;
      }
      {
        type = "disk";
        key = "◆ ";
        keyColor = ansiAccent;
      }
    ];
  };

  # ~/.config/fastfetch/logo.jsonc
  xdg.configFile."fastfetch/logo.jsonc".text = builtins.toJSON {
    "$schema" = fastfetchSchema;
    logo = {
      source = logoPath;
      color = {
        "1" = ansiAccent;
      };
      padding = {
        top = 1;
        right = 0;
      };
      printRemaining = true;
    };
    modules = [ ];
  };
}
