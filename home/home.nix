{
  config,
  pkgs,
  inputs,
  head ? false,
  darkMode ? true,
  ...
}:

{
  imports = [
    ./modules/network
    ./modules/shell
    ./modules/code
    ./modules/code/vscode/vscode-server.nix
  ]
  ++ (if head then [ ./head.nix ] else [ ]);

  nixpkgs.config.allowUnfree = true;

  # Home Manager settings
  home.username = "aristide";
  home.homeDirectory = "/home/aristide";
  home.stateVersion = "25.11";

  # Programs available on all systems
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableFishIntegration = true;
  };

  home.packages = with pkgs; [
    sox
  ];
}
