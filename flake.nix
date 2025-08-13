{
  description = "iynaix's dotfiles managed via NixOS and home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager-stable = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    # hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1&rev=918d8340afd652b011b937d29d5eea0be08467f5";

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence.url = "github:nix-community/impermanence";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    wfetch = {
      url = "github:iynaix/wfetch";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    focal = {
      url = "github:iynaix/focal";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ self, ... }:
    let
      system = "x86_64-linux";
      importPkgs =
        nixpkgs':
        import nixpkgs' {
          inherit system;
          config.allowUnfree = true;
        };
      nixpkgs-patched =
        let
          bootstrap-nixpkgs = importPkgs inputs.nixpkgs;
          # nixpkgs patches that have yet to be merged
          nixpkgsPatches = [ ];
        in
        bootstrap-nixpkgs.applyPatches {
          name = "nixpkgs-patched";
          src = inputs.nixpkgs;
          patches = map bootstrap-nixpkgs.fetchpatch2 nixpkgsPatches;
        };
      pkgs = importPkgs nixpkgs-patched;
      lib = import ./lib.nix {
        inherit (inputs.nixpkgs) lib;
        inherit pkgs;
        inherit (inputs) home-manager;
      };
      commonArgsForSystem = system: {
        inherit
          self
          inputs
          lib
          pkgs
          system
          ;
        specialArgs = {
          inherit self inputs;
        };
      };
      commonArgs = commonArgsForSystem system;
      # call with forAllSystems (commonArgs: function body)
      forAllSystems =
        fn:
        lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
          "x86_64-darwin"
          "aarch64-darwin"
        ] (system: fn (commonArgsForSystem system));
    in
    {
      nixosConfigurations = (import ./hosts/nixos.nix commonArgs) // (import ./hosts/iso commonArgs);

      homeConfigurations = import ./hosts/home-manager.nix commonArgs;

      # devenv for working on dotfiles, provides rust environment
      devShells = forAllSystems (_: {
        default = import ./shell.nix { inherit pkgs; };
      });

      inherit lib self;

      packages = forAllSystems (import ./packages);

      # templates for devenvs
      templates = import ./templates;
    };
}
