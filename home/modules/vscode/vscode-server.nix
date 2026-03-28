{ pkgs, lib, ... }:

let
  # Extensions pre-installed on all SSH remote servers (cursor-server / vscode-server).
  # These are symlinked into ~/.cursor-server/extensions/ and ~/.vscode-server/extensions/
  # so the remote server finds them immediately without downloading from the marketplace.
  serverExtensions =
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

  # Machine-level settings applied to all remote server sessions.
  # Written to ~/.cursor-server/data/Machine/settings.json (and vscode-server equivalent).
  serverSettings = {
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
    "sonarlint.pathToNodeExecutable" = "${pkgs.nodejs_22}/bin/node";
  };

  settingsJson = builtins.toJSON serverSettings;

  # Build a shell snippet that symlinks all extensions from the nix store.
  # Each vscode extension in nixpkgs lives at ${pkg}/share/vscode/extensions/<id>/
  linkExtensions = lib.concatMapStrings (ext: ''
    for d in "${ext}/share/vscode/extensions"/*/; do
      ln -sfn "$d" "$extDir/$(basename "$d")"
    done
  '') serverExtensions;
in

{
  # Machine-level settings for both remote server variants
  home.file.".cursor-server/data/Machine/settings.json".text = settingsJson;
  home.file.".vscode-server/data/Machine/settings.json".text = settingsJson;

  # Symlink extensions from the nix store into the server extension directories
  home.activation.vscodeRemoteExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for serverDir in "$HOME/.cursor-server" "$HOME/.vscode-server"; do
      extDir="$serverDir/extensions"
      mkdir -p "$extDir"
      ${linkExtensions}
    done
  '';
}
