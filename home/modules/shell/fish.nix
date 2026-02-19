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
      # Run fastfetch on interactive shell start
      if status is-interactive
        nf
      end
    '';
  };
}
