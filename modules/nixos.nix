{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    max-jobs = 2;
    cores = 6;

    # Qui peut parler au daemon Nix. Le défaut est `*` : n'importe quel compte
    # local peut lui soumettre des dérivations, donc faire construire et
    # exécuter du code par le daemon. On restreint aux deux seuls comptes qui
    # en ont l'usage — les comptes de service (greeter, ollama…) n'en ont pas.
    # NB : distinct de `trusted-users`, qu'on laisse à root seul : être
    # `allowed` autorise à construire, pas à contourner le bac à sable ni à
    # imposer des substituters.
    allowed-users = [
      "root"
      "aristide"
    ];
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # nix-ld for running unpatched dynamic executables on NixOS
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    fuse3
    icu
    nss
    openssl
    curl
    expat
  ];

  # System state version
  system.stateVersion = "25.11";
}
