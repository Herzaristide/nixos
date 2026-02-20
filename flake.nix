{
  description = "NixOS configurations for laptop, desktop, and WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    synthwave84-yazi = {
      url = "github:Miuzarte/synthwave84.yazi";
      flake = false;
    };
    stylix = {
      url = "github:nix-community/stylix";
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
  };

  outputs = { self, nixpkgs, home-manager, nixos-wsl, musnix, ... }@inputs: let
    system = "x86_64-linux";
  in {
    nixosConfigurations = {
      zola = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/zola/configuration.nix
        ];
        specialArgs = { inherit inputs; };
      };

      gary = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/gary/configuration.nix
        ];
        specialArgs = { inherit inputs; };
      };

      exupery = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/exupery/configuration.nix
        ];
        specialArgs = { inherit inputs; };
      };
    };
  };
}

