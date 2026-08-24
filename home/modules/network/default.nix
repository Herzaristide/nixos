{ ... }:

{
  imports = [
    ./git.nix
    # Désactivé : rclone-bisync est un oneshot sans TimeoutStartSec que sd-switch
    # démarre et attend pendant l'activation. Le resync initial dépasse le timeout
    # de 5 min de home-manager, qui le tue avant qu'une baseline soit écrite, puis
    # le relance — boucle infinie qui bloquait switch-to-configuration.
    # ./rclone.nix
    ./ssh.nix
  ];
}
