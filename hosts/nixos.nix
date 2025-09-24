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
        ./${host} # host specific configuration
        ./${host}/hardware.nix # host specific hardware configuration
        (inputs.import-tree ../nixos)
        (inputs.import-tree ../modules)
        ../overlays
        inputs.hjem.nixosModules.default
        inputs.home-manager.nixosModules.home-manager
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;

            extraSpecialArgs = {
              inherit
                inputs
                host
                self
                user
                isVm
                ;
              inherit (self) libCustom;
              isNixOS = true;
              isLaptop = host == "xps" || host == "framework";
              dots = "/persist/home/${user}/projects/dotfiles";
            };

            users.${user} = {
              imports = [
                inputs.nix-index-database.homeModules.nix-index
                inputs.niri.homeModules.niri
                inputs.mango.hmModules.mango
                ./${host}/home.nix # host specific home-manager configuration
                (inputs.import-tree ../home-manager)
              ];
            };
          };
        }
        # alias for home-manager
        (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" user ])
        (lib.mkAliasOptionModule [ "hj" ] [ "hjem" "users" user ])
        inputs.mango.nixosModules.mango
        inputs.impermanence.nixosModules.impermanence
        inputs.sops-nix.nixosModules.sops
        extraConfig
      ];
    };
  mkVm = host: mkNixosArgs: mkNixos host (mkNixosArgs // { isVm = true; });
}
