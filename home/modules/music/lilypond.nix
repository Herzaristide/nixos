{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lilypond
  ];
}
