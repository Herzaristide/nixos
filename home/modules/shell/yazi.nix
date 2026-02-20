{ config, pkgs, inputs, ... }:

{
  programs.yazi = {
    enable = true;
    # Silence warning: explicitly set to keep legacy default (home.stateVersion < 26.05)
    shellWrapperName = "yy";
  };
}
