{ pkgs, lib, ... }:

let
  # VSCode desktop extensions (mirrors server extensions + desktop-specific ones)
  extensions =
    with pkgs.vscode-extensions;
    [
      # Remote
      ms-vscode-remote.remote-ssh
      ms-vscode-remote.remote-ssh-edit
      # Language support
      ms-python.python
      jnoortheen.nix-ide
      arrterian.nix-env-selector
      golang.go
      rust-lang.rust-analyzer
      hashicorp.terraform
      bradlc.vscode-tailwindcss
      # Formatters & linters
      esbenp.prettier-vscode
      charliermarsh.ruff
      dbaeumer.vscode-eslint
      # Quality
      sonarsource.sonarlint-vscode
      # Containers
      ms-azuretools.vscode-containers
      ms-azuretools.vscode-docker
      # Utilities
      mkhl.direnv
      # Git
      # GitHub Copilot
      github.copilot-chat
    ]
    ++ [
      (pkgs.vscode-utils.extensionFromVscodeMarketplace {
        name = "vscode-mermaid-chart";
        publisher = "MermaidChart";
        version = "2.6.0";
        sha256 = "sha256-tgZokvZLlzj2/CQt8q1e1EK/rLfLgL/dNt9cbfwmxOk=";
      })
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
    "extensions.ignoreRecommendations" = true;
    "editor.tabSize" = 4;
    "editor.insertSpaces" = false;
    "editor.tabSizeType" = "fixed";
    "editor.detectIndentation" = false;
    "editor.wordWrap" = "on";
    "workbench.editor.wrapTabs" = true;
    "sonarlint.pathToNodeExecutable" = "${pkgs.nodejs_22}/bin/node";
    # "window.openFoldersInNewWindow" = "on";
    "workbench.activityBar.location" = "top";
    "terminal.integrated.fontSize" = lib.mkForce 12;
    "terminal.integrated.fontFamily" = "JetBrains Mono";
    "editor.mouseWheelZoom" = true;
    "editor.fontSize" = lib.mkForce 12;
    "editor.fontFamily" = "Monocraft";
    "editor.fontLigatures" = false;
  };

  # MCP servers (dedicated config, not user settings)
  mcp = {
    servers = {
      context7 = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "@upstash/context7-mcp@latest"
        ];
        type = "stdio";
      };
      playwright = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [ "@playwright/mcp@latest" ];
        type = "stdio";
      };
      docker = {
        command = "${pkgs.nodejs_22}/bin/npx";
        args = [
          "-y"
          "@docker/mcp-server"
        ];
        type = "stdio";
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
    mutableExtensionsDir = false;
    profiles.default = {
      extensions = extensions;
      userSettings = settings;
      keybindings = keybindings;
      userMcp = mcp;
    };
  };
}
