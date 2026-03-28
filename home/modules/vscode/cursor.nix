{ pkgs, lib, ... }:

let
  # Cursor desktop extensions
  extensions = with pkgs.vscode-extensions; [
  ];

  # Cursor desktop settings
  settings = {
    "[python]" = {
      "editor.defaultFormatter" = "charliermarsh.ruff";
      "editor.formatOnSave" = true;
      "editor.codeActionsOnSave" = {
        "source.fixAll.ruff" = "explicit";
      };
    };
    "[javascript]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[javascriptreact]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[typescript]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[typescriptreact]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[json]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[jsonc]" = {
      "editor.defaultFormatter" = "esbenp.prettier-vscode";
      "editor.formatOnSave" = true;
    };
    "[go]" = {
      "editor.defaultFormatter" = "golang.go";
      "editor.formatOnSave" = true;
    };
    "[terraform]" = {
      "editor.defaultFormatter" = "hashicorp.terraform";
      "editor.formatOnSave" = true;
    };
    "[terraform-vars]" = {
      "editor.defaultFormatter" = "hashicorp.terraform";
      "editor.formatOnSave" = true;
    };
    "[rust]" = {
      "editor.defaultFormatter" = "rust-lang.rust-analyzer";
      "editor.formatOnSave" = true;
    };
    "[nix]" = {
      "editor.defaultFormatter" = "jnoortheen.nix-ide";
      "editor.formatOnSave" = true;
    };
    "nix.enableLanguageServer" = true;
    "nix.serverPath" = "${pkgs.nixd}/bin/nixd";
    "nix.serverSettings" = {
      "nixd" = {
        "formatting" = {
          "command" = [ "${pkgs.nixfmt}/bin/nixfmt" ];
        };
      };
    };
    "editor.tabSize" = 4;
    "editor.insertSpaces" = false;
    "editor.tabSizeType" = "fixed";
    "editor.detectIndentation" = false;
    "editor.wordWrap" = "on";
    "workbench.editor.wrapTabs" = true;
    "sonarlint.pathToNodeExecutable" = "${pkgs.nodejs_22}/bin/node";
    # "window.openFoldersInNewWindow" = "on";
    "workbench.activityBar.location" = "top";
    "mcp" = {
      "servers" = {
        "context7" = {
          "command" = "${pkgs.nodejs_22}/bin/npx";
          "args" = [
            "-y"
            "@upstash/context7-mcp@latest"
          ];
        };
        "playwright" = {
          "command" = "${pkgs.nodejs_22}/bin/npx";
          "args" = [ "@playwright/mcp@latest" ];
        };
        "docker" = {
          "command" = "${pkgs.nodejs_22}/bin/npx";
          "args" = [
            "-y"
            "@docker/mcp-server"
          ];
        };
      };
    };
  };

  # Custom keybindings
  keybindings = [
    {
      key = "alt+a";
      command = "editor.action.commentLine";
      when = "editorTextFocus && !editorReadonly";
    }
  ];
in

{
  # Install Cursor with custom package
  home.packages = [ pkgs.code-cursor ];

  home.activation.cursorUserConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/Cursor/User"
    install -m0644 ${pkgs.writeText "cursor-settings.json" (builtins.toJSON settings)} \
      "$HOME/.config/Cursor/User/settings.json"
    install -m0644 ${pkgs.writeText "cursor-keybindings.json" (builtins.toJSON keybindings)} \
      "$HOME/.config/Cursor/User/keybindings.json"
  '';

  # Install extensions directory structure
  home.file.".cursor/extensions/.keep".text = "";

  # Link extensions to Cursor
  home.activation.cursorExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    CURSOR_EXTENSIONS_DIR="$HOME/.cursor/extensions"
    mkdir -p "$CURSOR_EXTENSIONS_DIR"
    ${lib.concatMapStringsSep "\n" (ext: ''
      ln -sf ${ext}/share/vscode/extensions/* "$CURSOR_EXTENSIONS_DIR/" 2>/dev/null || true
    '') extensions}
  '';
}
