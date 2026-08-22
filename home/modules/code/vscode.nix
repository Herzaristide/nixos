{
  pkgs,
  ...
}:

{
  # Zed reste l'éditeur principal (voir ./zed.nix). VS Code est ajouté en
  # second, déclaratif via home-manager. Paquet unfree : autorisé globalement
  # par nixpkgs.config.allowUnfree (modules/nixos.nix).
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
  };
}
