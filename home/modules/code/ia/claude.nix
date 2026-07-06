{ pkgs, ... }:

{
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    enableMcpIntegration = true;

    # Serveurs LSP pour l'outil LSP intégré de Claude Code (rendu dans .lsp.json).
    # Approche déclarative équivalente aux plugins LSP du marketplace, mais qui
    # couvre aussi Nix (hors des 11 langages des plugins officiels). Les binaires
    # sont pointés directement dans le store — pas de dépendance au PATH.
    lspServers = {
      rust = {
        command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
        extensionToLanguage = {
          ".rs" = "rust";
        };
      };
      python = {
        command = "${pkgs.pyright}/bin/pyright-langserver";
        args = [ "--stdio" ];
        extensionToLanguage = {
          ".py" = "python";
          ".pyi" = "python";
        };
      };
      nix = {
        command = "${pkgs.nixd}/bin/nixd";
        extensionToLanguage = {
          ".nix" = "nix";
        };
      };
    };

    settings = {
      theme = "dark-ansi";
      language = "French";
      model = "opus";
      # Pas de tips/suggestions rotatifs pendant le spinner.
      spinnerTipsEnabled = false;
      voiceEnabled = true;
      voice = {
        enabled = true;
        mode = "hold";
      };
      permissions = {
        allow = [
          "Bash(echo *)"
          "Bash(ls *)"
          "Bash(ls)"
          "Bash(cat *)"
          "Bash(pwd)"
          "Bash(whoami)"
          "Bash(hostname)"
          "Bash(uname *)"
          "Bash(df *)"
          "Bash(du *)"
          "Bash(free *)"
          "Bash(stat *)"
          "Bash(file *)"
          "Bash(which *)"
          "Bash(type *)"
          "Bash(find *)"
          "Bash(head *)"
          "Bash(tail *)"
          "Bash(wc *)"
          "Bash(sort *)"
          "Bash(uniq *)"
          "Bash(grep *)"
          "Bash(rg *)"
          "Bash(tree *)"
          "Bash(realpath *)"
          "Bash(readlink *)"
          "Bash(basename *)"
          "Bash(dirname *)"
          "Bash(pactl *)"
          "Bash(pw-cli *)"
          "Bash(pw-dump *)"
          "Bash(wpctl *)"
          "Bash(nix eval *)"
          "Bash(nix flake check *)"
          "Bash(nix flake show *)"
          "Bash(nix-instantiate *)"
          "Bash(nix-hash *)"
          "Bash(nix-store --query *)"
          "Bash(systemctl --user status *)"
          "Bash(systemctl status *)"
          "Bash(systemctl --user list-*)"
          "Bash(systemctl list-*)"
          "Bash(journalctl --user *)"
          "Bash(journalctl -u *)"
          "Bash(ip *)"
          "Bash(ss *)"
          "Bash(lsblk*)"
          "Bash(lsusb*)"
          "Bash(lspci*)"
          "Bash(rocm-smi*)"
          "Bash(rocminfo*)"
          "Bash(nvidia-smi*)"
        ];
        deny = [
          "Bash(find * -delete*)"
          "Bash(find * -exec *)"
          "Bash(find * -execdir *)"
          "Bash(find * -ok *)"
          "Bash(find * -okdir *)"
          "Bash(find * -fprint*)"
        ];
      };
    };
  };
}
