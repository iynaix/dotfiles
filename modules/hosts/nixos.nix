{
  config,
  inputs,
  self,
  ...
}:
let
  mkNixos =
    host:
    {
      system ? "x86_64-linux",
      isVm ? false,
      user ? "iynaix",
      extraConfig ? { },
    }:
    let
      nixpkgs-bootstrap = import inputs.nixpkgs { inherit system; };
      # apply patches from nixpkgs
      nixpkgs-patched = nixpkgs-bootstrap.applyPatches {
        name = "nixpkgs-iynaix";
        src = inputs.nixpkgs;
        patches = map nixpkgs-bootstrap.fetchpatch self.patches;
      };
      inherit (inputs.nixpkgs) lib;
      # alteratively, nixosSystem = import (nixpkgs-patched + "/nixos/lib/eval-config.nix")
    in
    lib.nixosSystem {
      pkgs = import nixpkgs-patched {
        inherit system;
        config.allowUnfree = true;
      };

      specialArgs = {
        inherit
          inputs
          self
          host
          isVm
          user
          ;
        isLaptop = host == "xps" || host == "framework";
        dots = "/persist/home/${user}/projects/dotfiles";
      };

      modules = [
        config.flake.nixosModules."host-${host}"
        config.flake.nixosModules.core
        ../../overlays
        inputs.hjem.nixosModules.default
        inputs.nix-index-database.nixosModules.nix-index
        # alias for hjem
        (lib.mkAliasOptionModule [ "hj" ] [ "hjem" "users" user ])
        inputs.noctalia.nixosModules.default
        inputs.mango.nixosModules.mango
        inputs.impermanence.nixosModules.impermanence
        inputs.sops-nix.nixosModules.sops
        extraConfig
      ];
    };
  mkVm = host: mkNixosArgs: mkNixos host (mkNixosArgs // { isVm = true; });
in
{
  flake.nixosConfigurations = {
    desktop = mkNixos "desktop" { };
    framework = mkNixos "framework" { };
    xps = mkNixos "xps" { };
    # VMs from config
    vm = mkVm "vm" { };
    # hyprland can be used within a VM on AMD
    vm-hyprland = mkVm "vm" { };
    # create VMs for each host configuration, build using
    # nixos-rebuild build-vm --flake .#desktop-vm
    desktop-vm = mkVm "desktop" { };
    framework-vm = mkVm "framework" { };
    xps-vm = mkVm "xps" { };
  };
}
