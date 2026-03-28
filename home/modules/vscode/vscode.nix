{ pkgs, ... }:

let
  # VSCode desktop extensions
  extensions = with pkgs.vscode-extensions; [
    ms-vscode-remote.remote-ssh
    ms-vscode-remote.remote-ssh-edit
  ];

  # VSCode desktop settings
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
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    mutableExtensionsDir = true;
    extensions = extensions;
    userSettings = settings;
    keybindings = keybindings;
  };
}
