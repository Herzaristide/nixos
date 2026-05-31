{ pkgs, ... }:

{
  programs.claude-code = {
    enable = true;
    package = pkgs.claude-code;
    enableMcpIntegration = true;
    settings = {
      theme = "dark-ansi";
      language = "French";
      model = "opus";
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
      };
    };
  };
}
