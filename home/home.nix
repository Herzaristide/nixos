{
  head ? false,
  ...
}:

let
  headlessModules = [
    ./modules/network
    ./modules/shell
    ./modules/code
  ];

  headfullModules = [
    ./head.nix
    ./modules/hyprland/hyprland.nix
    ./modules/hyprland/lock.nix
    ./modules/code/zed.nix
    ./modules/code/ia/claude-desktop.nix
    ./modules/alacritty.nix
    ./modules/quickshell.nix
    ./modules/hyprland/tofi.nix
    ./modules/teams.nix
    ./modules/discord.nix
    ./modules/obs.nix
    ./modules/onlyoffice.nix
    ./modules/penpot.nix
    ./modules/accent/accent.nix
    ./modules/kde
    ./modules/chromium.nix
    ./modules/blender.nix
    ./modules/music
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
    VISUAL = "zed --wait";
    PAGER = "less";
    MANPAGER = "less";
    BROWSER = "chromium";
    TERMINAL = "alacritty";
  };

}
