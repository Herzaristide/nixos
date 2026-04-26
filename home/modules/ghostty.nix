{ config, ... }:

{
  xdg.configFile."ghostty/config".text = ''
    font-family = JetBrains Mono
    font-size = 10

    # Appearance
    background-opacity = 0.0
    window-decoration = false
    cursor-style = bar
    cursor-style-blink = true

    # Padding
    window-padding-x = 16
    window-padding-y = 16

    # Scrollback
    scrollback-limit = 5000

    # Bell off
    bell-features = no-system,no-audio,no-attention

    # Shell integration for fish
    shell-integration = fish
    shell-integration-features = cursor,sudo,title

    # Splits — kitty-compatible layout
    keybind = alt+e=new_split:right
    keybind = alt+d=new_split:down
    keybind = alt+left=goto_split:left
    keybind = alt+right=goto_split:right
    keybind = alt+up=goto_split:up
    keybind = alt+down=goto_split:down
    keybind = alt+q=close_surface

    # New tab with cwd
    keybind = ctrl+shift+t=new_tab

    # Theme base (dark)
    background = 1d2021
    foreground = ebdbb2

    # Accent color defaults (overridden at runtime by config-file below).
    # accent-sync writes ~/.config/ghostty/accent-colors which is loaded
    # last; accentSeed seeds it on first install.
    palette = 4=#5277c3
    palette = 12=#5277c3
    cursor-color = #5277c3

    # Runtime-generated accent overrides (written by accent-sync, NOT by home-manager).
    # Ghostty silently ignores a missing config-file, so no error before accentSeed runs.
    config-file = ${config.home.homeDirectory}/.config/ghostty/accent-colors
  '';
}
