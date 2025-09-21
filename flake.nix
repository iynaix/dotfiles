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

    wrapper-manager.url = "github:viperML/wrapper-manager";

    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";

    # hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1&rev=918d8340afd652b011b937d29d5eea0be08467f5";

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mango = {
      url = "github:DreamMaoMao/mango";
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
    inputs@{ flake-parts, self, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (_: {
      flake =
        let
          inherit (inputs.nixpkgs) lib;
          pkgs = import inputs.nixpkgs {
            system = "x86_64-linux";
            config.allowUnfree = true;
          };
          user = "iynaix";
          hostNixosModule = import ./hosts/nixos.nix { inherit inputs self user; };
          inherit (hostNixosModule) mkNixos mkVm;
          mkHomeManager = import ./hosts/home-manager.nix { inherit inputs self; };
        in
        {
          nixosConfigurations = {
            desktop = mkNixos "desktop" { };
            framework = mkNixos "framework" { };
            xps = mkNixos "xps" { };
            # VMs from config
            vm = mkVm "vm" { };
            # hyprland can be used within a VM on AMD
            vm-hyprland = mkVm "vm" {
              extraConfig = {
                home-manager.users.${user}.custom.wm = lib.mkForce "hyprland";
              };
            };
            # create VMs for each host configuration, build using
            # nixos-rebuild build-vm --flake .#desktop-vm
            desktop-vm = mkVm "desktop" { isVm = true; };
            framework-vm = mkVm "framework" { isVm = true; };
            xps-vm = mkVm "xps" { isVm = true; };
          }
          // (import ./hosts/iso { inherit inputs self; });

          homeConfigurations = {
            desktop = mkHomeManager "x86_64-linux" user "desktop" { };
            framework = mkHomeManager "x86_64-linux" user "framework" { };
          };

          inherit lib;

          libCustom = import ./lib.nix { inherit lib pkgs; };

          inherit self; # for repl debugging

          templates = import ./templates;
        };
      systems = [
        # systems for which you want to build the `perSystem` attributes
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem =
        { pkgs, ... }:
        {
          devShells.default = import ./shell.nix { inherit pkgs; };
          packages = (import ./packages) { inherit inputs pkgs; };
        };
    });
}
