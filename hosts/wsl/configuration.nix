{
  config,
  inputs,
  lib,
  ...
}:

{
  imports = [
    inputs.home-manager.nixosModules.default
    inputs.nixos-wsl.nixosModules.default
    ../../modules/nixos.nix
    ../../modules/common.nix
    ../../modules/network.nix
  ];

  # Enable WSL integration
  wsl.enable = true;
  wsl.defaultUser = "aristide";

  services.xserver.enable = false;

  # Hostname
  networking.hostName = "wsl";

  # Head configuration
  head = false;

  # WSL-specific overrides (different from common.nix)

  # Disable bootloader - WSL doesn't use a bootloader
  boot.loader.systemd-boot.enable = false;
  boot.loader.grub.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;

  # Disable NetworkManager - WSL uses Windows networking
  networking.networkmanager.enable = false;
  networking.useDHCP = false;
  networking.useNetworkd = false;

  # CA locales, gardées hors du dépôt : tout `*.pem` déposé dans
  # /var/lib/extra-ca/ est ajouté au bundle système à chaque activation (sans
  # .pem, le bundle est identique à celui de nixpkgs). Pour un proxy qui
  # intercepte le TLS : exporter sa racine depuis le magasin Windows, pas
  # depuis une connexion interceptée, puis `nixos-rebuild switch`.
  system.activationScripts.extraCaBundle = ''
    mkdir -p /var/lib/extra-ca
    shopt -s nullglob
    cat ${config.security.pki.caBundle} /var/lib/extra-ca/*.pem > /var/lib/extra-ca/bundle.crt.tmp
    mv /var/lib/extra-ca/bundle.crt.tmp /var/lib/extra-ca/bundle.crt
  '';
  nix.settings.ssl-cert-file = "/var/lib/extra-ca/bundle.crt";

  # Set SSL certificate environment variables for curl/wget/Nix/Node
  environment.variables = {
    SSL_CERT_FILE = "/var/lib/extra-ca/bundle.crt";
    NIX_SSL_CERT_FILE = "/var/lib/extra-ca/bundle.crt";
    NODE_EXTRA_CA_CERTS = "/var/lib/extra-ca/bundle.crt";
  };

  # Git HTTPS credentials: Git for Windows' GCM, which stores tokens in the
  # Windows Credential Manager. The headless default (home/modules/network/git.nix)
  # is GCM's in-memory cache, lost after ~15 min and at every WSL restart —
  # and the company GitLab has no SSH, so HTTPS is the only way in.
  home-manager.users.aristide.programs.git.settings.credential = {
    helper = lib.mkForce "/mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe";
    credentialStore = lib.mkForce "wincredman";
  };
}
