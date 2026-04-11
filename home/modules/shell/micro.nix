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
      # Colorschemes disponibles nativement : default, monokai, zenburn,
      # gruvbox, darcula, solarized, simple, atom-dark, material, railscast,
      # twilight... (catppuccin n'est pas inclus par défaut)
      colorscheme = "default";
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
      # Le plugin auto-détecte les formateurs installés (prettier, black, rustfmt, etc.)
      "autofmt.fmtOnSave" = true;

      # Pas de dépôts de plugins supplémentaires
      pluginrepos = [ ];
    };
  };

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
