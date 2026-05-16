{ pkgs, ... }:

{
  # Alacritty config is managed by paletted via the template
  # ~/.config/accent/templates/alacritty.toml.tmpl
  # → rendered to ~/.config/alacritty/alacritty.toml on every accent change.
  # Do NOT use programs.alacritty.settings here — it creates an immutable
  # nix-store symlink that paletted cannot overwrite.
  home.packages = [ pkgs.alacritty ];
}
