{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "docker" "kubectl" ];
      theme = "robbyrussell";
    };
    shellAliases = {
      ll = "ls -l";
      la = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";
    };
    initContent = lib.mkOrder 1000 ''
      if [[ -o interactive ]]; then
        nf
      fi
    '';
  };
}
