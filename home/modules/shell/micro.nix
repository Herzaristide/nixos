{
  pkgs,
  lib,
  ...
}:

{
  programs.micro = {
    enable = true;

    # ~/.config/micro/settings.json
    # Options : https://github.com/zyedidia/micro/blob/master/runtime/help/options.md
    settings = {
      # Colorscheme statique : n'utilise que des noms ANSI (`red`, `bright-red`…),
      # remappés vers l'accent vif par wezterm. Aucun rendu dynamique nécessaire.
      colorscheme = "accent";
      autoindent = true;
      autosave = 0;
      cursorline = true;
      diffgutter = true;
      eofnewline = true;
      fastdirty = false;
      hlsearch = true;
      ignorecase = true;
      incsearch = true;
      indentchar = " ";
      mkparents = true;
      mouse = true;
      rmtrailingws = true;
      ruler = true;
      savecursor = true;
      saveundo = true;
      scrollbar = true;
      smartpaste = true;
      softwrap = true;
      splitbottom = true;
      splitright = true;
      statusline = true;
      syntax = true;
      tabmovement = true;
      tabsize = 4;
      tabstospaces = true;
      useprimary = true;

      "comment.type" = "auto";

      # Plugin autofmt : format on save avec formateurs externes.
      # Le plugin auto-détecte les formateurs installés (prettier, ruff, rustfmt, gofumpt, etc.)
      "autofmt.fmtOnSave" = true;

      # Pas de dépôts de plugins supplémentaires
      pluginrepos = [ ];
    };
  };

  # ~/.config/micro/colorschemes/accent.micro
  xdg.configFile."micro/colorschemes/accent.micro".text = ''
    color-link default                   "default,default"
    color-link comment                   "bold black"
    color-link identifier                "bright-red"
    color-link constant                  "red"
    color-link constant.string           "red"
    color-link constant.number           "red"
    color-link constant.bool             "red"
    color-link statement                 "red"
    color-link symbol.operator           "bright-red"
    color-link preproc                   "red"
    color-link type                      "bright-red"
    color-link special                   "red"
    color-link statusline                "white,color8"
    color-link tabbar                    "white,color8"
    color-link tabbar.active             "white,red"
    color-link indent-char               "bold black"
    color-link line-number               "bold black"
    color-link current-line-number       "red"
    color-link gutter-error              "red"
    color-link gutter-warning            "red"
    color-link cursor-line               "default"
    color-link color-column              "default"
    color-link match-brace               "red"
    color-link diff-added                "green"
    color-link diff-modified             "red"
    color-link diff-deleted              "red"
    color-link selection                 ",bold black"
    color-link hlsearch                  "default,bright-red"
    color-link message                   "red"
    color-link error                     "white,red"
    color-link info                      "red"
    color-link warning                   "red"
    color-link todo                      "bold red"
    color-link divider                   "color8"
  '';

  # ~/.config/micro/bindings.json
  xdg.configFile."micro/bindings.json".text = builtins.toJSON {
    # Commentaire (plugin comment, built-in)
    "CtrlE" = "lua:comment.comment";
    # Formatage (plugin autofmt)
    "Alt-f" = "command:format";
  };

  # Installation des plugins Micro externes via `micro -plugin install`.
  # NOTE : `comment` et `linter` sont des plugins built-in (déjà inclus),
  # inutile de les installer. Seul `autofmt` est externe.
  # Idempotent : ne réinstalle pas si le dossier du plugin existe déjà.
  home.activation.microPlugins = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    export PATH="${pkgs.micro}/bin:$PATH"
    mkdir -p "$HOME/.config/micro/plug"
    for plugin in autofmt; do
      if [ ! -d "$HOME/.config/micro/plug/$plugin" ]; then
        echo "[micro] installing plugin: $plugin"
        ${pkgs.micro}/bin/micro -plugin install "$plugin" \
          || echo "[micro] WARN: failed to install $plugin"
      fi
    done
  '';
}
