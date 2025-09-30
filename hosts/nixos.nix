{
  inputs,
  self,
  user ? "iynaix",
}:
rec {
  inherit (inputs.nixpkgs) lib;
  mkNixos =
    host:
    {
      isVm ? false,
      extraConfig ? { },
    }:
    lib.nixosSystem {
      specialArgs = {
        inherit
          inputs
          self
          host
          isVm
          user
          ;
        inherit (self) libCustom;
        isNixOS = true;
        isLaptop = host == "xps" || host == "framework";
        dots = "/persist/home/${user}/projects/dotfiles";
      };

      modules = [
        (inputs.import-tree ./${host}) # host specific configuration
        (inputs.import-tree ../modules)
        ../overlays
        inputs.hjem.nixosModules.default
        inputs.nix-index-database.nixosModules.nix-index
        inputs.niri.nixosModules.niri
        # alias for hjem
        (lib.mkAliasOptionModule [ "hj" ] [ "hjem" "users" user ])
        inputs.mango.nixosModules.mango
        inputs.impermanence.nixosModules.impermanence
        inputs.sops-nix.nixosModules.sops
        extraConfig
      ];
    };
  mkVm = host: mkNixosArgs: mkNixos host (mkNixosArgs // { isVm = true; });
}
