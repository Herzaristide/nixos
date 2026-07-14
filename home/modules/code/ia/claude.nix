{ pkgs, ... }:

{
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    enableMcpIntegration = true;

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
      spinnerTipsEnabled = false;
      voiceEnabled = true;
      voice = {
        enabled = true;
        mode = "hold";
      };
      hooks.PreToolUse = [
        {
          matcher = "Bash";
          hooks = [
            {
              type = "command";
              command = "rtk hook claude";
            }
          ];
        }
      ];

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
