{ config, pkgs, inputs, head ? false, ... }:

{
  imports = [
    ./modules/zsh.nix
  ] ++ (if head then [
    ./head.nix
  ] else []);

  nixpkgs.config.allowUnfree = true;


  # Home Manager settings
  home.username = "aristide";
  home.homeDirectory = "/home/aristide";
  home.stateVersion = "25.11";

  # Programs available on all systems
  programs = {
    git = {
      enable = true;
      settings = {
        user.name = "Herzaristide";
        user.email = "aristide.pichereau@gmail.com";
      };
    };
  };

  # Packages available on all systems
  home.packages = with pkgs; [
    claude-code
    yazi
    htop
    direnv
    sysstat
    btop
  ];
}

