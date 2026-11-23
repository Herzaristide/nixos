{
  head ? false,
  ...
}:

let
  headlessModules = [
    ./xdg.nix
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
    ./modules/kitty.nix
    ./modules/quickshell.nix
    ./modules/karenine-explorer.nix
    ./modules/karenine-world.nix
    ./modules/teams.nix
    ./modules/vesktop.nix
    ./modules/ajar.nix
    ./modules/accent/accent.nix
    ./modules/kde
    ./modules/chromium.nix
    ./modules/f3d.nix
    ./modules/viewers.nix
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
    TERMINAL = "kitty";
    # Claude Code ne marque ses liens (OSC 8) que dans les terminaux qu'il
    # reconnaît (TERM_PROGRAM, TERM=xterm-kitty…) : kitty oui, pas forcément
    # le terminal de Zed. Forcé partout ; les terminaux qui ne savent pas
    # les afficher les ignorent.
    FORCE_HYPERLINK = "1";
  };

}
