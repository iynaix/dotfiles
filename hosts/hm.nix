{
  inputs,
  system,
  specialArgs,
  user ? "elias-ainsworth",
  lib,
  ...
}:
let
  # provide an optional { pkgs } 2nd argument to override the pkgs
  mkHomeConfiguration =
    host:
    {
      pkgs ? (
        import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }
      ),
    }:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs lib;

      extraSpecialArgs = specialArgs // {
        inherit host user;
        isNixOS = false;
        isLaptop = host == "framework" || host == "x1c" || host == "t450";
      };

      modules = [
        inputs.nix-index-database.hmModules.nix-index
        inputs.nixvim.homeManagerModules.nixvim
        ./${host}/home.nix # host specific home-manager configuration
        ../home-manager
        ../overlays
      ];
    };
in
{
  desktop = mkHomeConfiguration "desktop" { };
  optiplex = mkHomeConfiguration "optiplex" { };
  framework = mkHomeConfiguration "framework" { };
  x1c = mkHomeConfiguration "x1c" { };
  t450 = mkHomeConfiguration "t450" { };
  # NOTE: standalone home-manager doesn't make sense for VM config!
}
