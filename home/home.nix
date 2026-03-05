{
  config,
  pkgs,
  inputs,
  head ? false,
  ...
}:

{
  imports = [
    ./modules/shell
    ./vscode-remote.nix
  ]
  ++ (
    if head then
      [
        ./head.nix
      ]
    else
      [ ]
  );

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
        credential.helper = "store";
        pull.rebase = true;
      };
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
      enableFishIntegration = true;
    };
  };

  # Packages available on all systems (non-hardware)
  home.packages = with pkgs; [
    claude-code
    cursor-cli
    nixfmt
  ];

  # Wget configuration - disable certificate checks
  home.file.".wgetrc".text = ''
    check_certificate = off
  '';
}
