{
  lib,
  inputs,
  user,
  ...
}: let
  createHost = {hostName}:
    lib.nixosSystem rec {
      system = "x86_64-linux";

      specialArgs = {
        inherit user inputs system;
        host = hostName;
      };

      modules =
        [
          ./configuration.nix # shared nixos configuration across all hosts
          ./${hostName} # host specific configuration, including hardware
          inputs.home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user} = {
                home = {
                  username = user;
                  homeDirectory = "/home/${user}";
                  # do not change this value
                  stateVersion = "22.11";
                };

                # Let Home Manager install and manage itself.
                programs.home-manager.enable = true;
              };
            };
            nixpkgs.overlays = import ../overlays;
          }
          inputs.impermanence.nixosModules.impermanence
          inputs.kmonad.nixosModules.default
        ]
        ++ lib.optionals (hostName == "laptop") [
          inputs.nixos-hardware.nixosModules.dell-xps-13-9343
        ];
    };
in {
  vm = createHost {hostName = "vm";};
  desktop = createHost {hostName = "desktop";};
  laptop = createHost {hostName = "laptop";};
}
