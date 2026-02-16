{
  description = "iynaix's dotfiles managed via NixOS and home-manager";

  inputs = {

    # nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    # channel urls are faster and more reliable than github -.-
    nixpkgs.url = "https://channels.nixos.org/nixos-unstable/nixexprs.tar.xz";
    nixpkgs-stable.url = "https://channels.nixos.org/nixos-25.11/nixexprs.tar.xz";

    # patch nixpkgs to use unmerged PRs
    nixpkgs-patcher.url = "github:gepbird/nixpkgs-patcher";

    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";

    hjem = {
      url = "github:feel-co/hjem";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        smfh.inputs.systems.follows = "systems";
      };
    };

    wrappers = {
      url = "github:Lassulus/wrappers";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1&rev=918d8340afd652b011b937d29d5eea0be08467f5";

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    wfetch = {
      url = "github:iynaix/wfetch";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    focal = {
      url = "github:iynaix/focal";
      inputs = {
        flake-parts.follows = "flake-parts";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    let
      inherit (inputs.nixpkgs.lib.fileset) toList fileFilter;
      import-tree =
        path:
        toList (fileFilter (file: file.hasExt "nix" && !(inputs.nixpkgs.lib.hasPrefix "_" file.name)) path);
    in
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = import-tree ./modules;

      flake.templates = import ./templates;
    };
}
