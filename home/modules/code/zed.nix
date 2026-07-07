{ pkgs, inputs, ... }:

let
  system = pkgs.stdenv.hostPlatform.system;
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
  dockerLs = "${pkgs.dockerfile-language-server-nodejs}/bin/docker-langserver";
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
    ];

    userSettings = {
      vim_mode = false;
      telemetry = {
        metrics = false;
        diagnostics = false;
      };

      # "Accent" (couleurs) est rendu par le daemon anna dans
      # ~/.config/zed/themes/ et suit la couleur d'accent du système.
      theme = {
        mode = "dark";
        dark = "Accent";
        light = "Accent";
      };
      # Icônes Catppuccin (extension catppuccin-icons).
      icon_theme = "Catppuccin Mocha";

      ui_font_family = "JetBrains Mono";
      buffer_font_family = "JetBrains Mono";
      buffer_font_size = 14;

      # Fichiers (worktree) + git à gauche, terminal à droite.
      project_panel = {
        dock = "left";
        indent_size = 10;
      };
      git_panel = {
        dock = "left";
      };
      terminal = {
        dock = "right";
        toolbar.breadcrumbs = false;
      };

      # Complétions inline (edit predictions) désactivées : plus de Copilot,
      # ce qui évite le lancement du copilot-language-server (~440 Mio).
      features = {
        edit_prediction_provider = "none";
      };
      show_edit_predictions = false;

      format_on_save = "on";

      # Retour à la ligne automatique à la largeur de l'éditeur.
      soft_wrap = "editor_width";

      tab_bar = {
        show = false;
      };
      #max_tabs = 1;

      # Un seul fichier ouvert à la fois : chaque navigation remplace l'onglet courant.
      preview_tabs = {
        enabled = true;
        enable_preview_from_file_finder = true;
        enable_preview_from_code_navigation = true;
      };

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
        vtsls.binary.path = vtsls;
        docker-langserver.binary = {
          path = dockerLs;
          arguments = [ "--stdio" ];
        };
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
      };
    };

    # Alt+A : commenter / décommenter la ligne ou la sélection.
    # Alt+R : ouvrir les projets récents.
    # Alt+Q : focus arborescence de fichiers.
    # Alt+G : focus panneau git.
    # Alt+E : focus éditeur.
    # Alt+T : focus terminal.
    userKeymaps = [
      {
        context = "Editor";
        bindings = {
          "alt-a" = "editor::ToggleComments";
        };
      }
      {
        context = "Workspace";
        bindings = {
          "alt-r" = "projects::OpenRecent";
          "alt-q" = "project_panel::ToggleFocus";
          "alt-g" = "git_panel::ToggleFocus";
          "alt-t" = "terminal_panel::ToggleFocus";
        };
      }
      # Alt+E depuis l'arborescence → retour éditeur
      {
        context = "ProjectPanel";
        bindings = {
          "alt-e" = "workspace::ActivateLastPane";
        };
      }
      # Alt+E depuis le terminal → retour éditeur
      {
        context = "Terminal";
        bindings = {
          "alt-e" = "terminal_panel::ToggleFocus";
        };
      }
    ];
  };
}
