{ config, pkgs, inputs, lib, ... }:

{
  # Option for head (GUI) configuration
  options.head = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = "Enable head (GUI) configuration";
  };


  config = {

    nixpkgs.config.allowUnfree = true;
    # Networking
    networking.networkmanager.enable = true;

    # Timezone and locale
    time.timeZone = "Europe/Paris";
    i18n.defaultLocale = "en_US.UTF-8";
    i18n.extraLocaleSettings = {
      LC_ADDRESS = "fr_FR.UTF-8";
      LC_IDENTIFICATION = "fr_FR.UTF-8";
      LC_MEASUREMENT = "fr_FR.UTF-8";
      LC_MONETARY = "fr_FR.UTF-8";
      LC_NAME = "fr_FR.UTF-8";
      LC_NUMERIC = "fr_FR.UTF-8";
      LC_PAPER = "fr_FR.UTF-8";
      LC_TELEPHONE = "fr_FR.UTF-8";
      LC_TIME = "fr_FR.UTF-8";
    };

    # User account
    users.users.aristide = {
      isNormalUser = true;
      description = "aristide";
      extraGroups = [ "networkmanager" "wheel" "docker"];
      packages = with pkgs; [ ];
      shell = pkgs.zsh;
    };

    # Docker
    virtualisation.docker.enable = true;


    # System state version
    system.stateVersion = "25.11";

    # Home Manager
    home-manager = {
      extraSpecialArgs = { 
        inherit inputs; 
        head = config.head;
      };
      users.aristide = import ../home/home.nix;
    };
  };
}


