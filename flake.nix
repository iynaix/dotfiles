{
  description = "iynaix's dotfiles managed via NixOS and home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-23.11";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devenv.url = "github:cachix/devenv";

    impermanence.url = "github:nix-community/impermanence";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wfetch = {
      url = "github:iynaix/wfetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NOTE: This will require your git SSH access to the repo.
    # disable ghostty by commenting out the following input and setting
    # the hm option config.custom.ghostty.enable = false
    #
    # WARNING: Do NOT pin the `nixpkgs` input, as that will
    # declare the cache useless. If you do, you will have
    # to compile LLVM, Zig and Ghostty itself on your machine,
    # which will take a very very long time.
    ghostty = {
      url = "git+ssh://git@github.com/mitchellh/ghostty";
    };
  };

  # flake-utils is unnecessary
  # https://ayats.org/blog/no-flake-utils/
  outputs =
    inputs@{ nixpkgs, self, ... }:
    let
      system = "x86_64-linux";
      forAllSystems =
        function: nixpkgs.lib.genAttrs [ system ] (system: function nixpkgs.legacyPackages.${system});
      commonArgs = {
        inherit (nixpkgs) lib;
        inherit self inputs nixpkgs;
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        specialArgs = {
          inherit self inputs;
        };
      };
    in
    {
      nixosConfigurations = (import ./hosts/nixos.nix commonArgs) // (import ./hosts/iso commonArgs);

      homeConfigurations = import ./hosts/hm.nix commonArgs;

      # devenv for working on dotfiles, provides rust environment
      devShells = forAllSystems (pkgs: {
        default = import ./devenv.nix {
          inherit inputs;
          inherit (pkgs) system;
        };
      });

      # legacyPackages = forAllSystems (pkgs: pkgs);

      packages = forAllSystems (pkgs: (import ./packages { inherit pkgs inputs; }));

      # templates for devenvs
      templates = import ./templates;
    };
}
