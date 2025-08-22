{
  inputs,
  self,
  pkgs,
}:
# 2nd argument is unused, maybe extraConfig in future?
userWithhost: _:
let
  inherit (self) lib;
  _parts = lib.splitString "@" userWithhost;
  user = lib.elemAt _parts 0;
  host = lib.elemAt _parts 1;
in
inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs lib;

  extraSpecialArgs = {
    inherit
      inputs
      self
      host
      user
      ;
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
    (inputs.import-tree ../home-manager)
    ../overlays
  ];
}
