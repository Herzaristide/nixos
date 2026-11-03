{ pkgs, ... }:

{
  # Antigravity CLI (`agy`) : client TUI agentique de Google, paquet nixpkgs
  # (unfree, allowUnfree est déjà actif). Importé par ./default.nix, donc
  # seulement pour aristide — pas pour l'utilisateur `claude` des agents.
  home.packages = [ pkgs.antigravity-cli ];
}
