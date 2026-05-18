{ pkgs, ... }:

{
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    # Required by nixd (Nix IDE) when evaluating flake-based options/expressions.
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Capped parallelism so the machine stays usable while ROCm rebuilds.
    # 2 concurrent derivations × 6 threads each leaves headroom on Ryzen 5 1600 (6c/12t).
    max-jobs = 2;
    cores = 6;
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
