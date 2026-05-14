{
  config,
  pkgs,
  inputs,
  head ? false,
  darkMode ? true,
  ...
}:

let
  headlessModules = [
    ./modules/network
    ./modules/shell
    ./modules/code
    ./modules/code/vscode/vscode-server.nix
  ];

  headfullModules = [
    ./head.nix
    ./modules/hyprland.nix
    ./modules/code/vscode/vscode.nix
    ./modules/wezterm.nix
    ../quickshell/quickshell.nix
    ./modules/walker.nix
    ./modules/accent/accent.nix
    ./modules/kde.nix
    ./modules/chromium.nix
  ];
in
{
  imports = headlessModules ++ (if head then headfullModules else [ ]);

  # Home Manager settings
  home.username = "aristide";
  home.homeDirectory = "/home/aristide";
  home.stateVersion = "25.11";

  home.sessionVariables = {
    EDITOR = "micro";
    VISUAL = "micro";
    PAGER = "less";
    MANPAGER = "less";
    BROWSER = "chromium";
    TERMINAL = "wezterm";
  };
}
