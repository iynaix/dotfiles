{
  inputs,
  pkgs,
  specialArgs,
  user ? "iynaix",
  ...
}:
let
  mkHomeConfiguration =
    host:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = specialArgs // {
        inherit host user;
        isNixOS = false;
        isLaptop = host == "xps" || host == "framework";
      };

      modules = [
        inputs.nix-index-database.hmModules.nix-index
        inputs.nixvim.homeManagerModules.nixvim
        ./${host}/home.nix # host specific home-manager configuration
        ../home-manager
        ../modules/home-manager
        ../overlays
      ];
    };
in
{
  desktop = mkHomeConfiguration "desktop";
  framework = mkHomeConfiguration "framework";
  xps = mkHomeConfiguration "xps";
  # NOTE: standalone home-manager doesn't make sense for VM config!
}
