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
        isLaptop = host == "framework" || host == "x1c" || host == "t520" || host == "t450";
        isVm = host == "vm" || host == "vm-hyprland";
        # NOTE: don't reference /persist on legacy distros
        dots = "/home/${user}/projects/dotfiles";

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
  framework = mkHomeConfiguration "framework" { };
  x1c = mkHomeConfiguration "x1c" { };
  t520 = mkHomeConfiguration "t520" { };
  t450 = mkHomeConfiguration "t450" { };
  # NOTE: standalone home-manager doesn't make sense for VM config!
}
