{ pkgs, ... }:

{
  # rtk (Rust Token Killer) — proxy CLI qui filtre/compresse la sortie des
  # commandes avant qu'elle n'atteigne le contexte du LLM (-60 à -90% de
  # tokens sur git/tests/build/etc.). Packagé dans nixpkgs.
  # Hooks PreToolUse : voir ./claude.nix.
  home.packages = [ pkgs.rtk ];
}
