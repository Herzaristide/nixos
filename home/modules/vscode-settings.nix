{ pkgs, ... }:

{
  # Shared VSCode extensions list - used by both local VSCode and remote servers
  extensions =
    with pkgs.vscode-extensions;
    [
      ms-python.python
      charliermarsh.ruff
      sonarsource.sonarlint-vscode
      dbaeumer.vscode-eslint
      esbenp.prettier-vscode
      mkhl.direnv
      jnoortheen.nix-ide
      arrterian.nix-env-selector
      bradlc.vscode-tailwindcss
      golang.go
      hashicorp.terraform
      rust-lang.rust-analyzer
      ms-azuretools.vscode-containers
      ms-azuretools.vscode-docker
      anthropic.claude-code
      bierner.markdown-mermaid
    ]
    ++ [
      # Extensions from marketplace (not in nixpkgs)
      (pkgs.vscode-utils.extensionFromVscodeMarketplace {
        name = "vscode-mermaid-chart";
        publisher = "MermaidChart";
        version = "2.6.0";
        sha256 = "sha256-tgZokvZLlzj2/CQt8q1e1EK/rLfLgL/dNt9cbfwmxOk=";
      })
    ];

  # Shared VSCode settings - used by both local VSCode and remote servers
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
    "window.openFoldersInNewWindow" = "on";
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
}
