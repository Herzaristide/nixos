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
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Periodic rebuild from git — daily at 04:00, no reboot
  system.autoUpgrade = {
    enable = true;
    flake = "github:Herzaristide/nixos";
    flags = [
      "--update-input"
      "nixpkgs"
      "--no-write-lock-file"
      "-L"
    ];
    dates = "04:00";
    randomizedDelaySec = "30min";
    persistent = true;
    allowReboot = false;
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
