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
rec {
  desktop = mkHomeConfiguration "desktop";
  framework = mkHomeConfiguration "framework";
  xps = mkHomeConfiguration "xps";
  vm = mkHomeConfiguration "vm";
  vm-amd = vm // {
    config.custom-nixos.hyprland.enable = true;
  };
}
