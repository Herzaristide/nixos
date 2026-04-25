{ config, pkgs, ... }:

{
  home.packages = [ pkgs.kitty ];

  programs.kitty = {
    enable = true;

    font = {
      name = "JetBrains Mono";
      size = 10;
    };

    settings = {
      # Appearance — fully transparent background (compositor handles opacity)
      background_opacity = "0.0";
      window_padding_width = 16;
      hide_window_decorations = "yes";
      cursor_shape = "beam";
      cursor_blink_interval = "0.5";
      scrollback_lines = 5000;

      # Remote control via Unix socket — accent-sync uses `kitten @ set-colors`
      # to live-update colors without relying on SIGUSR1 config reload.
      allow_remote_control = "socket-only";
      listen_on = "unix:/tmp/kitty-{kitty_pid}";

      # Tab bar — colors managed via kitty-accent.conf include
      tab_bar_edge = "bottom";
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      # Simple title: let active_tab_foreground (= accent) apply via include
      tab_title_template = " {index} {title[:20]} ";

      # Bell off
      enable_audio_bell = "no";
    };

    keybindings = {
      # Splits — match the previous Wezterm Alt-based layout.
      "alt+e" = "launch --location=hsplit --cwd=current";
      "alt+d" = "launch --location=vsplit --cwd=current";
      "alt+left" = "neighboring_window left";
      "alt+right" = "neighboring_window right";
      "alt+up" = "neighboring_window up";
      "alt+down" = "neighboring_window down";
      "alt+q" = "close_window";
      # New tab keeps the current working directory.
      "ctrl+shift+t" = "new_tab_with_cwd";
    };

    # Pull in the runtime-generated accent overrides (color4/color12/cursor/...).
    # accent-sync regenerates this file and sends SIGUSR1 to kitty for live reload.
    extraConfig = ''
      include ${config.home.homeDirectory}/.config/accent/kitty-accent.conf
    '';
  };
}
