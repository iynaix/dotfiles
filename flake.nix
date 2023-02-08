{
  description = "iynaix's dotfiles managed via nixos and home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = { # Official Hyprland flake
      url = "github:vaxerski/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ { self, nixpkgs, home-manager, hyprland, ... }:
    let
      user = "iynaix";
    in {
      nixosConfigurations = (
        # imports ./hosts/default.nix
        import ./hosts {
          inherit (nixpkgs) lib;
          inherit inputs nixpkgs home-manager user hyprland;
        }
      );
    };
}
