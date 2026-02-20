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
    vscode = {
      enable = true;
      package = pkgs.code-cursor;
      mutableExtensionsDir = true;
      profiles = {
        default = {
          extensions = with pkgs.vscode-extensions; [
            ms-python.python
            charliermarsh.ruff
            sonarsource.sonarlint-vscode
            dbaeumer.vscode-eslint
            esbenp.prettier-vscode
            mkhl.direnv
            jnoortheen.nix-ide
            arrterian.nix-env-selector
            bradlc.vscode-tailwindcss
            ms-azuretools.vscode-containers
            ms-azuretools.vscode-docker
          ];
          userSettings = {
            "[python]" = {
              "editor.defaultFormatter" = "charliermarsh.ruff";
              "editor.formatOnSave" = true;
              "editor.codeActionsOnSave" = {
                "source.fixAll.ruff" = "explicit";
              };
            };
          };
        };
      };
    };
  };

  # Packages available on all systems (non-hardware)
  home.packages = with pkgs; [
    claude-code
    nixfmt
  ];

  # Wget configuration - disable certificate checks
  home.file.".wgetrc".text = ''
    check_certificate = off
  '';
}
