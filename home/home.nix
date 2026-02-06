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

    yazi = {
      enable = true;
      # settings = { };  # ~/.config/yazi/yazi.toml
      # keymap = { };    # ~/.config/yazi/keymap.toml
      # theme = { };     # ~/.config/yazi/theme.toml
    };
  };

  # Packages available on all systems (non-hardware)
  home.packages = with pkgs; [
    claude-code
    direnv
  ];
}

