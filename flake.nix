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
    explorer.url = "github:Herzaristide/Explorer";
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

      install-nixos-pkg = pkgs.stdenvNoCC.mkDerivation {
        pname = "install-nixos";
        version = "0.1";
        dontUnpack = true;
        nativeBuildInputs = [ pkgs.makeWrapper ];
        installPhase = ''
          install -Dm755 ${./install.sh} $out/bin/install-nixos
          wrapProgram $out/bin/install-nixos --prefix PATH : "${
            pkgs.lib.makeBinPath [
              pkgs.git
              pkgs.nixos-install-tools
            ]
          }"
        '';
        meta.description = "Clone flake to /etc/nixos, regenerate hardware, rebuild";
      };
    in
    {
      packages.${system} = {
        install-nixos = install-nixos-pkg;
        paletted = accent-daemon-pkg;
      };

      apps.${system}.install-nixos = {
        type = "app";
        program = "${install-nixos-pkg}/bin/install-nixos";
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
            ./hosts/zola/disko.nix
            ./hosts/zola/configuration.nix
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
            ./hosts/exupery/configuration.nix
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
