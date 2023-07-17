{
  description = "iynaix's dotfiles managed via nixos and home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprwm-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    kmonad = {
      url = "github:kmonad/kmonad?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # flake-utils is unnecessary
  # https://ayats.org/blog/no-flake-utils/
  outputs = inputs @ {nixpkgs, ...}: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
      ] (system: function nixpkgs.legacyPackages.${system});
    commonInherits = {
      inherit (nixpkgs) lib;
      inherit inputs nixpkgs;
      user = "iynaix";
      system = "x86_64-linux";
    };
  in {
    nixosConfigurations = import ./hosts (
      commonInherits // {isNixOS = true;}
    );

    homeConfigurations = import ./hosts (
      commonInherits // {isNixOS = false;}
    );

    formatter = nixpkgs.alejandra;

    # devshell for working on dotfiles, provides python utilities
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs.python311Packages; [
          flake8
          black
        ];
      };
    });

    # templates for devenv
    templates = let
      welcomeText = ''
        # `.devenv` should be added to `.gitignore`
        ```sh
          echo .devenv >> .gitignore
        ```
      '';
    in rec {
      javascript = {
        inherit welcomeText;
        path = ./templates/javascript;
        description = "Javascript / Typescript dev environment";
      };

      python = {
        inherit welcomeText;
        path = ./templates/python;
        description = "Python dev environment";
      };

      js = javascript;
      ts = javascript;

      py = python;
    };
  };
}
