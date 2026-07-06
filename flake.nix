{
  description = "NixOS configurations for laptop, desktop, and WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    musnix = {
      url = "github:musnix/musnix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    karenine = {
      url = "github:Herzaristide/karenine";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        localSystem = system;
        config.allowUnfree = true;
      };

      accent-daemon-pkg = import ./accent-daemon/default.nix { inherit pkgs; };
    in
    {
      packages.${system} = {
        paletted = accent-daemon-pkg;
      };

      homeConfigurations = {
        "aristide" = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          extraSpecialArgs = {
            inherit inputs;
            head = false;
            darkMode = true;
            primaryMonitor = "HDMI-A-1";
            accentDaemon = pkgs.callPackage ./accent-daemon/default.nix { };
          };
          modules = [
            ./home/home.nix
            (
              { lib, pkgs, ... }:
              {
                home.username = lib.mkForce "apichere";
                home.homeDirectory = lib.mkForce "/home/apichere";
                home.packages = [
                  pkgs.nix
                  pkgs.docker
                ];
              }
            )
          ];
        };
      };

      nixosConfigurations = {
        zola = nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
            inputs.disko.nixosModules.disko
            ./modules/disko.nix
            ./hosts/zola/configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };

        gary = nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
            inputs.disko.nixosModules.disko
            ./modules/disko.nix
            ./hosts/gary/configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };

        exupery = nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
            ./hosts/exupery/configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };

        kafka = nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
            inputs.disko.nixosModules.disko
            # Disko dédié : ESP sur clé USB (relais de boot), NVMe = LUKS+btrfs.
            # Le firmware du T3610 ne sait pas booter le NVMe.
            ./hosts/kafka/disko.nix
            ./hosts/kafka/configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };
      };
    };
}
