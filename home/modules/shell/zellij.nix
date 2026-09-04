{ pkgs, ... }:

let
  shortcuts = import ../shortcuts.nix { inherit pkgs; };

  zellijKeybinds = builtins.concatStringsSep "\n" (
    map (
      { keys, actions, ... }:
      "    bind \"${keys}\" { ${
            builtins.concatStringsSep "; " (actions ++ [ ''SwitchToMode "Normal"'' ])
          }; }"
    ) shortcuts.zellij
  );
in
{
  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
    # false = une session neuve par terminal. À true, l'auto-start fish lance
    # `zellij attach -c` (sans nom), qui rattache toutes les fenêtres à la
    # dernière session vivante : mêmes onglets, mêmes panes, curseur partagé.
    attachExistingSession = false;
    exitShellOnExit = true;
  };

  xdg.configFile."zellij/config.kdl".force = true;
  xdg.configFile."zellij/config.kdl".text = ''
    theme "accent"
    default_layout "default"
    pane_frames false
    show_startup_tips false
    show_release_notes false
    support_kitty_keyboard_protocol true
    copy_clipboard "system"
    copy_on_select true

    themes {
      accent {
        fg 7
        bg 1
        black 0
        red 1
        green 1
        yellow 3
        blue 1
        magenta 1
        cyan 6
        white 7
        orange 1
      }
    }

    plugins {
      tab-bar location="zellij:tab-bar"
      status-bar location="zellij:status-bar"
      compact-bar location="zellij:compact-bar"
      configuration location="zellij:configuration"
      session-manager location="zellij:session-manager"
      strider location="zellij:strider"
      filepicker location="zellij:strider" { cwd "/"; }
      about location="zellij:about"
      plugin-manager location="zellij:plugin-manager"
      welcome-screen location="zellij:session-manager" { welcome_screen true; }
    }

    keybinds {
      shared_except "locked" {
    ${zellijKeybinds}
      }
    }
  '';

  xdg.configFile."zellij/layouts/default.kdl".force = true;
  xdg.configFile."zellij/layouts/default.kdl".text = ''
    layout {
      pane
    }
  '';
}
