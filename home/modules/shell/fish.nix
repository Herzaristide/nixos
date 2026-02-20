{
  config,
  pkgs,
  lib,
  ...
}:

{
  programs.fish = {
    enable = true;
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
    };
    interactiveShellInit = ''
      # Disable fish greeting message
      set -U fish_greeting ""

      # Run fastfetch on interactive shell start
      if status is-interactive
        nf
      end
    '';
  };
}
