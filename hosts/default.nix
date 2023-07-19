{
  lib,
  inputs,
  user,
  system,
  isNixOS,
  ...
}: let
  mkHost = {hostName}: let
    extraSpecialArgs = {
      inherit inputs isNixOS system user;
      host = hostName;
      isLaptop = hostName == "laptop";
    };
  in
    if isNixOS
    then
      lib.nixosSystem {
        specialArgs = extraSpecialArgs;

        modules =
          [
            ./configuration.nix # shared nixos configuration across all hosts
            ./${hostName} # host specific configuration, including hardware
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                inherit extraSpecialArgs;

                users.${user} = {
                  imports = [
                    ../home-manager
                    ../modules/home-manager
                  ];

                  # Let Home Manager install and manage itself.
                  programs.home-manager.enable = true;
                };
              };
            }
            inputs.impermanence.nixosModules.impermanence
            inputs.kmonad.nixosModules.default
          ]
          ++ lib.optionals (hostName == "laptop") [
            inputs.nixos-hardware.nixosModules.dell-xps-13-9343
          ];
      }
    else {};
in {
  vm = mkHost {hostName = "vm";};
  desktop = mkHost {hostName = "desktop";};
  laptop = mkHost {hostName = "laptop";};
}
