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

  # Programs available on all systems
  programs = {
    git = {
      enable = true;
      settings = {
        user.name = "Herzaristide";
        user.email = "aristide.pichereau@gmail.com";
        credential.helper = "store";
        pull.rebase = false;
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

  # Claude Code MCP servers (~/.claude.json)
  # Figma remote MCP: authenticate via /mcp in Claude Code when first connecting.
}
