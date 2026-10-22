{ inputs, ... }:

# Ajar — espace d'écriture zen (github:Herzaristide/ajar). Les livres vont
# par défaut dans $XDG_DOCUMENTS_DIR/Ajar, soit ~/docs/Ajar (cf. xdg.nix),
# déjà persisté ; l'état de session (~/.local/state/ajar) l'est dans
# modules/impermanence.nix.
{
  imports = [ inputs.ajar.homeManagerModules.default ];

  programs.ajar.enable = true;
}
