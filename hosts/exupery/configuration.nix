{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    inputs.home-manager.nixosModules.default
    inputs.nixos-wsl.nixosModules.default
    ../../modules/common.nix
  ];

  # Enable WSL integration
  wsl.enable = true;
  wsl.defaultUser = "aristide";

  services.xserver.enable = false;

  # Hostname
  networking.hostName = "exupery";

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

  # Set SSL certificate environment variables for curl/wget/etc
  # Note: Corporate proxy (Capgemini) is intercepting SSL - bypass verification for WSL development
  environment.variables = {
    SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    NIX_SSL_CERT_FILE = "/etc/ssl/certs/ca-bundle.crt";
    NODE_TLS_REJECT_UNAUTHORIZED = "0";
    GIT_SSL_NO_VERIFY = "true";
  };

  

  # SSH - allow connections without authentication (WSL only, local access)
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitEmptyPasswords = true;
      KbdInteractiveAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Allow user to have empty password for passwordless SSH access
  users.users.aristide = {
    hashedPassword = null; # No password hash - allows empty password
    initialHashedPassword = ""; # Set initial empty password
  };

  # Configure PAM to allow empty passwords for SSH
  security.pam.services.sshd = {
    # Allow empty passwords (nullok option)
    text = ''
      auth       required     pam_unix.so     nullok
      account    required     pam_unix.so
      password   required     pam_unix.so     nullok
      session    required     pam_unix.so
    '';
  };
}
