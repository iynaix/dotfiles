{
  inputs,
  specialArgs,
  lib,
  ...
}@args:
let
  # provide an optional { pkgs } 2nd argument to override the pkgs
  mkHomeConfiguration =
    userWithhost:
    {
      pkgs ? args.pkgs,
    }:
    let
      _parts = lib.splitString "@" userWithhost;
      user = lib.elemAt _parts 0;
      host = lib.elemAt _parts 1;
    in
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs lib;

      extraSpecialArgs = specialArgs // {
        inherit host user;
        isNixOS = false;
        isLaptop = host == "xps" || host == "framework";
        isVm = false;
        # NOTE: don't reference /persist on legacy distros
        dots = "/home/${user}/projects/dotfiles";
      };

      modules = [
        inputs.nix-index-database.homeModules.nix-index
        inputs.niri.homeModules.niri
        inputs.mango.hmModules.mango
        ./${host}/home.nix # host specific home-manager configuration
        ../home-manager
        ../overlays
      ];
    };
in
{
  desktop = mkHomeConfiguration "iynaix@desktop" { };
  framework = mkHomeConfiguration "iynaix@framework" { };
  # NOTE: standalone home-manager doesn't make sense for VM config!
}
