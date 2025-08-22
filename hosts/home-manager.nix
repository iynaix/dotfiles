{
  inputs,
  self,
}:
# last argument is unused, maybe extraConfig in future?
system: user: host: _:
inputs.home-manager.lib.homeManagerConfiguration {
  pkgs = import inputs.nixpkgs {
    inherit system;
    config.allowUnfree = true;
  };

  extraSpecialArgs = {
    inherit
      inputs
      self
      host
      user
      ;
    inherit (self) libCustom;
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
