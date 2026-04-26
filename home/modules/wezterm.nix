{ pkgs, ... }:

{
  # WezTerm config is managed by accent-sync via the template
  # ~/.config/accent/templates/wezterm-accent.lua.tmpl
  # → rendered to ~/.config/wezterm/wezterm.lua on every accent change.
  # Do NOT use programs.wezterm.extraConfig here — it creates an immutable
  # nix-store symlink that accent-sync cannot overwrite.
  home.packages = [ pkgs.wezterm ];
}
