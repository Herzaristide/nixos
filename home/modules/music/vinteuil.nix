{ inputs, ... }:

# Vinteuil — pupitre zen pour les partitions LilyPond
# (github:Herzaristide/vinteuil). Le binaire vient du cache Cachix rempli par
# sa CI ; voir l'entrée `vinteuil` de flake.nix.
{
  imports = [ inputs.vinteuil.homeManagerModules.default ];

  programs.vinteuil.enable = true;
}
