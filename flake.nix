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
    impermanence.url = "github:nix-community/impermanence";
    ajar = {
      url = "github:Herzaristide/ajar";
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

      # anna — moteur unifié (thème accent/palette + stats matérielles), fourni
      # par le flake karenine (auparavant le paquet local accent-daemon).
      anna = inputs.karenine.packages.${system}.anna;

      # Claude Desktop : repackaging du .deb officiel (absent de nixpkgs).
      claude-desktop = pkgs.callPackage ./pkgs/claude-desktop { };
    in
    {
      packages.${system} = {
        anna = anna;
        claude-desktop = claude-desktop;
      };

      # Shell de travail sur ce dépôt : `nix develop`.
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.nixfmt
        ];
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
            anna = anna;
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
        bernanos = nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
            inputs.disko.nixosModules.disko
            ./hosts/bernanos/disko.nix
            ./hosts/bernanos/configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };

        gary = nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
            inputs.disko.nixosModules.disko
            ./hosts/gary/disko.nix
            ./hosts/gary/configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };

        exupery = nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
            inputs.disko.nixosModules.disko
            ./hosts/exupery/disko.nix
            ./hosts/exupery/configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };

        wsl = nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
            ./hosts/wsl/configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };

        kafka = nixpkgs.lib.nixosSystem {
          modules = [
            { nixpkgs.hostPlatform = system; }
            inputs.disko.nixosModules.disko
            ./hosts/kafka/disko.nix
            ./hosts/kafka/configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };
      };
    };
}
