{
  head ? false,
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
    ./modules/hyprland/hyprland.nix
    ./modules/hyprland/hyprlock.nix
    ./modules/code/vscode/vscode.nix
    ./modules/alacritty.nix
    ../quickshell/quickshell.nix
    ./modules/hyprland/tofi.nix
    ./modules/vesktop.nix
    ./modules/sioyek.nix
    ./modules/accent/accent.nix
    ./modules/kde.nix
    ./modules/chromium.nix
    ./modules/minecraft.nix
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
    TERMINAL = "alacritty";
  };
}
