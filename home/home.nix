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
    ./modules/vscode/vscode-server.nix
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

  # Services
  services.ssh-agent.enable = true;

  # Programs available on all systems
  programs = {
    git = {
      enable = true;
      settings = {
        user.name = "Herzaristide";
        user.email = "aristide.pichereau@gmail.com";
        gpg.format = "ssh";
        commit.gpgSign = true;
        init.defaultBranch = "main";
        pull.rebase = false;
      };
      signing = {
        key = "~/.ssh/siddhartha.pub";
        signByDefault = true;
      };
    };

    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        # GitHub (clé siddhartha pour auth + signing)
        "github.com" = {
          hostname = "github.com";
          user = "git";
          identityFile = "~/.ssh/siddhartha";
          identitiesOnly = true;
        };
        # GitLab (clé sisyphe)
        "gitlab.com" = {
          hostname = "gitlab.com";
          user = "git";
          identityFile = "~/.ssh/sisyphe";
          identitiesOnly = true;
        };
        # Serveur gary (clé salammbo)
        "gary" = {
          hostname = "192.168.1.138";
          user = "aristide";
          identityFile = "~/.ssh/salammbo";
          identitiesOnly = true;
        };
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
}
