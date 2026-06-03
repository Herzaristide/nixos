{ ... }:

{
  programs.zellij = {
    enable = true;
    enableFishIntegration = false;
  };

  xdg.configFile."zellij/config.kdl".force = true;
  xdg.configFile."zellij/config.kdl".text = ''
    theme "accent"
    default_layout "default"
    pane_frames true
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

    keybinds clear-defaults=true {
      shared_except "locked" {
        bind "Ctrl Left"  { MoveFocus "left"; }
        bind "Ctrl Down"  { MoveFocus "down"; }
        bind "Ctrl Up"    { MoveFocus "up"; }
        bind "Ctrl Right" { MoveFocus "right"; }

        bind "Ctrl h" { MoveFocus "left"; }
        bind "Ctrl j" { MoveFocus "down"; }
        bind "Ctrl k" { MoveFocus "up"; }
        bind "Ctrl l" { MoveFocus "right"; }

        bind "Ctrl Enter" { NewPane; }
        bind "Ctrl q" { CloseFocus; }
        bind "Ctrl d" { NewPane "down"; }
        bind "Ctrl r" { NewPane "right"; }
        bind "Ctrl f" { ToggleFocusFullscreen; }
        bind "Ctrl e" { TogglePaneEmbedOrFloating; }
        bind "Ctrl w" { ToggleFloatingPanes; }
        bind "Ctrl z" { TogglePaneFrames; }

        bind "Ctrl s" { SwitchToMode "resize"; }
        bind "Ctrl o" { SwitchToMode "session"; }
        bind "Ctrl g" { SwitchToMode "locked"; }
      }

      locked {
        bind "Ctrl g" { SwitchToMode "normal"; }
      }

      resize {
        bind "Left"  { Resize "Increase left"; }
        bind "Down"  { Resize "Increase down"; }
        bind "Up"    { Resize "Increase up"; }
        bind "Right" { Resize "Increase right"; }
        bind "h" { Resize "Increase left"; }
        bind "j" { Resize "Increase down"; }
        bind "k" { Resize "Increase up"; }
        bind "l" { Resize "Increase right"; }
        bind "H" { Resize "Decrease left"; }
        bind "J" { Resize "Decrease down"; }
        bind "K" { Resize "Decrease up"; }
        bind "L" { Resize "Decrease right"; }
        bind "+" { Resize "Increase"; }
        bind "-" { Resize "Decrease"; }
        bind "Ctrl s" { SwitchToMode "normal"; }
        bind "esc"    { SwitchToMode "normal"; }
        bind "enter"  { SwitchToMode "normal"; }
      }

      session {
        bind "w" {
          LaunchOrFocusPlugin "session-manager" {
            floating true
            move_to_focused_tab true
          }
          SwitchToMode "normal"
        }
        bind "c" {
          LaunchOrFocusPlugin "configuration" {
            floating true
            move_to_focused_tab true
          }
          SwitchToMode "normal"
        }
        bind "d" { Detach; }
        bind "Ctrl o" { SwitchToMode "normal"; }
        bind "esc"    { SwitchToMode "normal"; }
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
