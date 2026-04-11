{
  description = "NixOS configurations for laptop, desktop, and WSL";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
    danksearch = {
      url = "github:AvengeMedia/danksearch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    voicemode = {
      url = "github:mbailey/voicemode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      nixos-wsl,
      musnix,
      dms,
      danksearch,
      quickshell,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

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
      packages.${system}.install-nixos = install-nixos-pkg;

      apps.${system}.install-nixos = {
        type = "app";
        program = "${install-nixos-pkg}/bin/install-nixos";
      };

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

        kafka = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            ./hosts/kafka/configuration.nix
          ];
          specialArgs = { inherit inputs; };
        };
      };
    };
}
