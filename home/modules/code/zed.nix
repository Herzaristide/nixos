{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;

  shortcuts = import ../shortcuts.nix { inherit pkgs; };
  # Language servers / formatters fournis par Nix (au lieu des binaires
  # auto-téléchargés par Zed, qui ne tournent pas sur NixOS — linker dynamique).
  nixd = "${pkgs.nixd}/bin/nixd";
  nixfmt = "${pkgs.nixfmt}/bin/nixfmt";
  pyright = "${pkgs.pyright}/bin/pyright-langserver";
  ruff = "${pkgs.ruff}/bin/ruff";
  gopls = "${pkgs.gopls}/bin/gopls";
  rustAnalyzer = "${pkgs.rust-analyzer}/bin/rust-analyzer";
  terraformLs = "${pkgs.terraform-ls}/bin/terraform-ls";
  tailwindLs = "${pkgs.tailwindcss-language-server}/bin/tailwindcss-language-server";
  vtsls = "${pkgs.vtsls}/bin/vtsls";
  biome = "${pkgs.biome}/bin/biome";
  dockerLs = "${pkgs.dockerfile-language-server}/bin/docker-langserver";
  sqls = "${pkgs.sqls}/bin/sqls";
  qmlls = "${pkgs.qt6.qtdeclarative}/bin/qmlls";

  # qmlls ne lit pas QML_IMPORT_PATH sans `-E`, et l'env de Zed ne définit de
  # toute façon que l'ancien QML2_IMPORT_PATH (ignoré par Qt6). On lui passe donc
  # les chemins des modules en dur via `-I` : Qt6 (QtQuick, QtQml, QtCore,
  # QtQuick.Controls/Layouts/Effects — tous dans qtdeclarative) + Quickshell
  # (tiré comme input de flake). Sans ça, tous les imports QML échouent et le
  # linter crache des milliers de faux warnings « unqualified access ».
  qmlImportArgs = [
    "-I"
    "${pkgs.qt6.qtdeclarative}/lib/qt-6/qml"
    "-I"
    "${inputs.quickshell.packages.${system}.default}/lib/qt-6/qml"
  ];
in
{
  # Binaires aussi sur le PATH (utiles hors Zed : shell, autres outils).
  home.packages = [
    pkgs.nixd
    pkgs.nixfmt
    pkgs.pyright
    pkgs.ruff
    pkgs.gopls
    pkgs.rust-analyzer
    pkgs.terraform-ls
    pkgs.tailwindcss-language-server
    pkgs.vtsls
    pkgs.dockerfile-language-server
    pkgs.biome
    pkgs.sqls
  ];

  programs.zed-editor = {
    enable = true;
    package = pkgs.zed-editor;

    extensions = [
      "nix"
      "toml"
      "dockerfile"
      "terraform"
      "mermaid"
      "lilypond"
      "catppuccin-icons"
      "qml"
      "sql"
      "kotlin"
      "lua"
      "java"
      "biome"
    ];

    userSettings = {
      telemetry = {
        metrics = false;
        diagnostics = false;
      };

      theme = {
        mode = "dark";
        dark = "Accent";
        light = "Accent";
      };
      # Icônes colorées Catppuccin (extension catppuccin-icons, déjà installée).
      icon_theme = "Catppuccin Mocha";

      # ui_font_family = "Dank Mono";
      ui_font_size = 16;
      # buffer_font_family = "Dank Mono";
      buffer_font_size = 14;
      # Interligne : valeur par défaut de Zed ("comfortable" = 1.618).
      buffer_line_height = "comfortable";
      agent_buffer_font_size = 16;
      # Ctrl + molette pour changer la taille de la police du code.
      mouse_wheel_zoom = true;
      features = {
        edit_prediction_provider = "zed";
      };
      show_edit_predictions = true;

      # Pas de config `title_bar` : la barre du haut ne pouvant pas être masquée
      # entièrement, on laisse Zed afficher son contenu par défaut (branche,
      # projet, menus, bouton de connexion Zed pour Zeta…).
      tab_bar = {
        show = false;
        show_tab_bar_buttons = false;
      };
      toolbar = {
        quick_actions = false;
        # Masque le fil d'Ariane (chemin/nom du fichier) en haut de l'éditeur.
        breadcrumbs = false;
      };
      status_bar = {
        "experimental.show" = false;
      };

      # Terminal ancré dans le dock de gauche (l'éditeur au centre, arborescence
      # et git à droite). Sur un dock latéral c'est `default_width` qui compte
      # (default_height ne s'applique qu'au dock du bas).
      terminal = {
        dock = "left";
        default_width = 640;
      };
      # `false` (défaut Zed) : re-déclencher le ToggleFocus d'un panneau déjà
      # focus rend le focus à l'éditeur SANS fermer le dock. Indispensable au
      # flux « tout est du focus » : le dock droit (arborescence + git, deux
      # onglets) reste toujours ouvert, et Alt+E / Alt+G ne font que déplacer le
      # focus entre l'éditeur et l'onglet voulu — jamais fermer. Avec `true`,
      # passer de git à l'arborescence via Alt+E fermait le dock (Zed voyant le
      # dock « déjà focus ») au lieu de basculer d'onglet.
      close_panel_on_toggle = false;

      # Panneau git à droite (il cohabite dans le dock droit avec project_panel,
      # comme deux onglets d'un même dock).
      git_panel = {
        dock = "right";
      };

      project_panel = {
        dock = "right";
        default_width = 400;
        hide_root = true;
        auto_fold_dirs = false;
        starts_open = true;
        git_status = false;
        sticky_scroll = false;
        scrollbar = {
          show = "never";
        };
        indent_guides = {
          show = "never";
        };
      };
      outline_panel = {
        default_width = 300;
        indent_guides = {
          show = "never";
        };
      };
      file_finder = {
        modal_max_width = "large";
      };
      scrollbar = {
        show = "never";
      };
      minimap = {
        # Les diagnostics ne sont pas (encore) affichés dans la minimap :
        # feature request zed-industries/zed#58453.
        show = "always";
      };
      # Gouttière réduite au strict minimum : plus de numéros de ligne, de folds,
      # de runnables ni de bookmarks — on ne garde que les points de debug
      # (breakpoints). Zed n'a pas d'option pour masquer la gouttière à 100 % ;
      # elle reste donc une fine bande dédiée aux pastilles de breakpoint.
      gutter = {
        line_numbers = true;
        folds = false;
        runnables = false;
        breakpoints = false;
        bookmarks = false;
      };
      indent_guides = {
        enabled = false;
      };

      # Retour à la ligne activé par défaut, calé sur la largeur de l'éditeur.
      # (alt-z bascule toujours ce comportement au cas par cas — voir shortcuts.nix.)
      soft_wrap = "editor_width";

      multi_cursor_modifier = "cmd_or_ctrl";
      cursor_shape = "bar";
      cursor_blink = false;
      selection_highlight = false;
      drag_and_drop_selection = {
        enabled = false;
      };
      seed_search_query_from_cursor = "never";
      current_line_highlight = "none";
      show_whitespaces = "none";
      tab_size = 2;
      auto_indent = true;
      auto_indent_on_paste = true;
      show_completions_on_input = false;
      show_completion_documentation = false;
      inline_code_actions = false;
      lsp_document_colors = "none";
      hover_popover_enabled = true;
      # Diagnostics : uniquement via le popover de survol — pas de texte en
      # gris sous la ligne (inline désactivé).
      diagnostics = {
        inline = {
          enabled = false;
        };
      };
      format_on_save = "on";
      autosave = {
        after_delay = {
          milliseconds = 1000;
        };
      };
      auto_update = false;
      extend_comment_on_newline = false;
      horizontal_scroll_margin = 1;
      vertical_scroll_margin = 1;
      when_closing_with_no_tabs = "keep_window_open";
      close_on_file_delete = true;
      restore_on_file_reopen = false;
      restore_on_startup = "last_session";
      session = {
        restore_unsaved_buffers = false;
      };
      trust_all_worktrees = true;
      git = {
        git_gutter = "hide";
        inline_blame = {
          enabled = false;
        };
      };
      # centered_layout = {
      #   right_padding = 0.15;
      #   left_padding = 0.15;
      # };

      # Chemins explicites vers les serveurs fournis par Nix.
      lsp = {
        nixd.binary.path = nixd;
        "pyright".binary = {
          path = pyright;
          arguments = [ "--stdio" ];
        };
        ruff.binary = {
          path = ruff;
          arguments = [ "server" ];
        };
        rust-analyzer.binary.path = rustAnalyzer;
        gopls.binary.path = gopls;
        terraform-ls.binary = {
          path = terraformLs;
          arguments = [ "serve" ];
        };
        tailwindcss-language-server.binary.path = tailwindLs;
        vtsls.binary = {
          path = vtsls;
          # `--stdio` est obligatoire en pratique : sans lui, vtsls 0.3.0 crash
          # au démarrage (« Connection input stream is not set ») bien que
          # --help le présente comme le défaut (cf. Zed.log).
          arguments = [ "--stdio" ];
        };
        biome.binary = {
          path = biome;
          # En Biome 2.x la sous-commande est `lsp-proxy` (et non `lsp`, qui
          # n'existe plus) : sans elle Biome affiche son aide et se termine → le
          # LSP n'initialise jamais (cf. Zed.log).
          arguments = [ "lsp-proxy" ];
        };
        docker-langserver.binary = {
          path = dockerLs;
          arguments = [ "--stdio" ];
        };
        # sqls defaulte vers le mode LSP stdio (pas d'arg --stdio, contrairement
        # à pyright/vtsls). La connexion Postgres se configure dans
        # ~/.config/sqls/config.yml (hors Nix — secrets).
        sqls.binary.path = sqls;
        # Extension « qml » (lkroll/zed-qml) : l'id du serveur est « qmljs ».
        qmljs.binary = {
          path = qmlls;
          arguments = qmlImportArgs;
        };
      };

      languages = {
        Nix = {
          language_servers = [
            "nixd"
            "!nil"
          ];
          formatter = {
            external = {
              command = nixfmt;
            };
          };
        };
        Python = {
          language_servers = [
            "pyright"
            "ruff"
          ];
          formatter = [ { language_server.name = "ruff"; } ];
        };
        # Biome : format + lint web (cohabite avec vtsls pour l'intellisense TS).
        JavaScript = {
          language_servers = [ "biome" ];
          formatter = [ { language_server.name = "biome"; } ];
        };
        TypeScript = {
          language_servers = [
            "vtsls"
            "biome"
          ];
          formatter = [ { language_server.name = "biome"; } ];
        };
        JSON = {
          language_servers = [ "biome" ];
          formatter = [ { language_server.name = "biome"; } ];
        };
        SQL = {
          language_servers = [ "sqls" ];
        };
      };
    };

    # Raccourcis définis dans home/modules/shortcuts.nix (source de vérité
    # partagée avec Alacritty/Hyprland/zellij/micro). Regroupés par context,
    # dans l'ordre d'apparition de shortcuts.zed (Editor, Workspace,
    # ProjectPanel, Terminal, MarkdownPreview).
    userKeymaps =
      let
        contexts = lib.unique (map (e: e.context) shortcuts.zed);
      in
      map (ctx: {
        context = ctx;
        bindings = builtins.listToAttrs (
          map (e: {
            name = e.key;
            value = e.action;
          }) (builtins.filter (e: e.context == ctx) shortcuts.zed)
        );
      }) contexts;
  };
}
