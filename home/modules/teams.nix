{ pkgs, ... }:

{
  # Microsoft Teams via teams-for-linux (client Electron non officiel).
  # Microsoft n'ayant plus de client Linux natif, ce wrapper gère mieux les
  # appels, le partage d'écran et les notifications système qu'un simple PWA.
  home.packages = [ pkgs.teams-for-linux ];
}
