{
  inputs,
  self,
  pkgs,
  user ? "iynaix",
}:
rec {
  mkNixos =
    host:
    {
      isVm ? false,
      extraConfig ? { },
    }:
    self.lib.nixosSystem {
      inherit pkgs;

      specialArgs = {
        inherit
          inputs
          self
          host
          isVm
          user
          ;
        isNixOS = true;
        isLaptop = host == "xps" || host == "framework";
        dots = "/persist/home/${user}/projects/dotfiles";
      };

      modules = [
        ./${host} # host specific configuration
        ./${host}/hardware.nix # host specific hardware configuration
        (inputs.import-tree ../nixos)
        ../overlays
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
        (self.lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" user ])
        inputs.mango.nixosModules.mango
        inputs.impermanence.nixosModules.impermanence
        inputs.sops-nix.nixosModules.sops
        extraConfig
      ];
    };
  mkVm = host: mkNixosArgs: mkNixos host (mkNixosArgs // { isVm = true; });
}
