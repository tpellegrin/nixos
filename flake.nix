{
  description = "Personal NixOS Configuration";

  inputs = {
    # Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    # Home Manager.
    home-manager.url = "github:nix-community/home-manager/release-24.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs: let
    inherit (self) outputs;
    system = "x86_64-linux";
  in {
    # Custom packages and modifications.
    overlays = import ./overlays { inherit inputs; };
    
    # NixOS modules.
    nixosModules = import ./modules/nixos;
    # Home Manager modules.
    homeManagerModules = import ./modules/home-manager;

    # NixOS configuration entrypoint.
    nixosConfigurations = {
      # Hostname.
      nixos = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs outputs; };
        system = "x86_64-linux";
        modules = [
          # Hardware configuration file.
          ./hardware-configuration.nix
          # Main NixOS configuration file.
          ./configuration.nix
          # Services module.
          ./services.nix
          # Gaming module.
          ./modules/gaming/default.nix
        ];
      };
    };

    # Home Manager configuration entrypoint.
    homeConfigurations = {
      "thiago@nixos" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        extraSpecialArgs = { inherit inputs outputs; };
        modules = [
          # Main Home Manager configuration file.
          ./home-manager/home.nix
        ];
      };
    };
  };
}
