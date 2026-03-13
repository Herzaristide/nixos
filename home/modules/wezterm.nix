{ pkgs, ... }:

{
  home.packages = with pkgs; [
    wezterm
  ];

  # Wezterm configuration (separate file to avoid Nix string parsing of Lua)
  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;
}
