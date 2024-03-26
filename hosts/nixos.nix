{
  inputs,
  lib,
  pkgs,
  specialArgs,
  user ? "iynaix",
  ...
}:
let
  mkNixosConfiguration =
    host:
    lib.nixosSystem {
      inherit pkgs;

      specialArgs = specialArgs // {
        inherit host user;
        isNixOS = true;
        isLaptop = host == "xps" || host == "framework";
      };

      modules = [
        ./${host} # host specific configuration
        ./${host}/hardware.nix # host specific hardware configuration
        ../nixos
        ../modules/nixos
        ../overlays
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;

            extraSpecialArgs = specialArgs // {
              inherit host user;
              isNixOS = true;
              isLaptop = host == "xps" || host == "framework";
            };

            users.${user} = {
              imports = [
                inputs.nix-index-database.hmModules.nix-index
                inputs.nixvim.homeManagerModules.nixvim
                ./${host}/home.nix # host specific home-manager configuration
                ../home-manager
                ../modules/home-manager
              ];
            };
          };
        }
        # alias for home-manager
        (lib.mkAliasOptionModule [ "hm" ] [
          "home-manager"
          "users"
          user
        ])
        inputs.impermanence.nixosModules.impermanence
        inputs.sops-nix.nixosModules.sops
      ];
    };
in
rec {
  desktop = mkNixosConfiguration "desktop";
  framework = mkNixosConfiguration "framework";
  xps = mkNixosConfiguration "xps";
  vm = mkNixosConfiguration "vm";
  vm-amd = vm // {
    config.custom-nixos.hyprland.enable = true;
  };
}
