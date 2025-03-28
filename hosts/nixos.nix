{
  inputs,
  lib,
  specialArgs,
  user ? "iynaix",
  ...
}@args:
let
  # provide an optional { pkgs } 2nd argument to override the pkgs
  mkNixosConfiguration =
    host:
    {
      pkgs ? args.pkgs,
      isVm ? false,
      extraConfig ? { },
    }:
    lib.nixosSystem {
      inherit pkgs;

      specialArgs = specialArgs // {
        inherit host user isVm;
        isNixOS = true;
        isLaptop = host == "xps" || host == "framework";
        dots = "/persist/home/${user}/projects/dotfiles";
      };

      modules = [
        ./${host} # host specific configuration
        ./${host}/hardware.nix # host specific hardware configuration
        ../nixos
        ../overlays
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;

            extraSpecialArgs = specialArgs // {
              inherit host user isVm;
              isNixOS = true;
              isLaptop = host == "xps" || host == "framework";
              dots = "/persist/home/${user}/projects/dotfiles";
            };

            users.${user} = {
              imports = [
                inputs.nix-index-database.hmModules.nix-index
                ./${host}/home.nix # host specific home-manager configuration
                ../home-manager
              ];
            };
          };
        }
        # alias for home-manager
        (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" user ])
        inputs.impermanence.nixosModules.impermanence
        inputs.sops-nix.nixosModules.sops
        extraConfig
      ];
    };
  mkVm =
    host: mkNixosConfigurationArgs:
    mkNixosConfiguration host (mkNixosConfigurationArgs // { isVm = true; });
in
{
  desktop = mkNixosConfiguration "desktop" { };
  framework = mkNixosConfiguration "framework" { };
  xps = mkNixosConfiguration "xps" { };
  vm = mkVm "vm" { };
  # hyprland can be used within a VM on AMD
  vm-hyprland = mkVm "vm" {
    extraConfig = {
      custom.plasma.enable = lib.mkForce false;
      home-manager.users.${user}.custom.hyprland.enable = lib.mkOverride (50 - 1) true;
    };
  };
  # create VMs for each host configuration, build using
  # nixos-rebuild build-vm --flake .#desktop-vm
  desktop-vm = mkVm "desktop" { isVm = true; };
  framework-vm = mkVm "framework" { isVm = true; };
  xps-vm = mkVm "xps" { isVm = true; };
}
