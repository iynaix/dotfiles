{
  inputs,
  lib,
  system,
  specialArgs,
  user ? "elias-ainsworth",
  ...
}:
let
  # provide an optional { pkgs } 2nd argument to override the pkgs
  mkNixosConfiguration =
    host:
    {
      pkgs ? (
        import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      ),
    }:
    lib.nixosSystem {
      inherit pkgs;

      specialArgs = specialArgs // {
        inherit host user;
        isNixOS = true;
        isLaptop = host == "xps" || host == "framework";
        isVm = host == "vm" || host == "vm-hyprland";
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
{
  desktop = mkNixosConfiguration "desktop" { };
  framework = mkNixosConfiguration "framework" { };
  xps = mkNixosConfiguration "xps" { };
  vm = mkNixosConfiguration "vm" { };
  vm-hyprland = mkNixosConfiguration "vm-hyprland" { };
}
