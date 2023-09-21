{
  description = "iynaix's dotfiles managed via NixOS and home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixpkgs-vscode.url = "github:nixos/nixpkgs/db9208ab987cdeeedf78ad9b4cf3c55f5ebd269b";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    hyprland = {
      url = "github:hyprwm/Hyprland/6594b50e57935dd66930ccd35dba7a1b4131399d";
      # inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprwm-contrib = {
      url = "github:hyprwm/contrib";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprNStack = {
      url = "github:iynaix/hyprNStack";
      inputs.hyprland.follows = "hyprland";
    };

    nix-index-database = {
      url = "github:Mic92/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvfetcher = {
      url = "github:berberman/nvfetcher/0.6.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # flake-utils is unnecessary
  # https://ayats.org/blog/no-flake-utils/
  outputs = inputs @ {nixpkgs, ...}: let
    forAllSystems = function:
      nixpkgs.lib.genAttrs ["x86_64-linux"] (system: function nixpkgs.legacyPackages.${system});
    commonInherits = {
      inherit (nixpkgs) lib;
      inherit inputs nixpkgs;
      user = "iynaix";
      system = "x86_64-linux";
    };
  in {
    nixosConfigurations = import ./hosts (commonInherits // {isNixOS = true;});

    homeConfigurations = import ./hosts (commonInherits // {isNixOS = false;});

    # devshell for working on dotfiles, provides python utilities
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs.python3.pkgs; [
          flake8
          black
        ];
      };
    });

    packages = forAllSystems (
      pkgs: (import ./packages {inherit pkgs;})
    );

    # templates for devenv
    templates = let
      welcomeText = ''
        # `.devenv` and `direnv` should be added to `.gitignore`
        ```sh
          echo .devenv >> .gitignore
          echo .direnv >> .gitignore
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

      rust = {
        inherit welcomeText;
        path = ./templates/rust;
        description = "Rust dev environment";
      };

      js = javascript;
      ts = javascript;
      py = python;
      rs = rust;
    };
  };
}
