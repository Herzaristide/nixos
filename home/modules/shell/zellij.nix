{ ... }:

{
  programs.zellij = {
    enable = true;
    # Pas d'auto-start dans fish : zellij interfère avec l'intégration shell
    # de Konsole (OSC 7, suivi de cwd côté Dolphin). Lancer manuellement via `z`.
    enableFishIntegration = false;
  };

  xdg.configFile."zellij/config.kdl".force = true;
  xdg.configFile."zellij/config.kdl".text = ''
    theme "accent"
    default_layout "default"
    pane_frames false
    show_startup_tips false
    show_release_notes false
    support_kitty_keyboard_protocol true
    copy_command "wl-copy"
    copy_clipboard "system"
    copy_on_select true

    // Indices ANSI 0-15 — Alacritty remappe le slot 1 (red) vers @ACCENT@
    // via ~/.config/accent/fragments/alacritty-colors.toml, donc tout ce qui
    // est tagué `red` ici prend la couleur d'accent en live (comme starship/fastfetch).
    themes {
      accent {
        fg 7
        bg 0
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
  '';

  xdg.configFile."zellij/layouts/default.kdl".force = true;
  xdg.configFile."zellij/layouts/default.kdl".text = ''
    layout {
      pane
    }
  '';
}
