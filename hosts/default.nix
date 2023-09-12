{
  lib,
  inputs,
  user,
  isNixOS,
  ...
}: let
  mkHost = host: let
    extraSpecialArgs = {
      inherit inputs isNixOS host user;
      isLaptop = host == "laptop";
    };
  in
    if isNixOS
    then
      lib.nixosSystem {
        specialArgs = extraSpecialArgs;

        modules =
          [
            ./configuration.nix # shared nixos configuration across all hosts
            ./${host} # host specific configuration
            ./${host}/hardware.nix # host specific hardware configuration
            ../nixos
            ../modules/nixos
            ../overlays
            inputs.home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;

                inherit extraSpecialArgs;

                users.${user} = {
                  imports = [
                    inputs.nix-index-database.hmModules.nix-index
                    inputs.impermanence.nixosModules.home-manager.impermanence
                    ./${host}/home.nix # host specific home-manager configuration
                    ../home-manager
                    ../modules/home-manager
                  ];

                  # Let Home Manager install and manage itself.
                  programs.home-manager.enable = true;
                };
              };
            }
            # alias for home-manager
            (lib.mkAliasOptionModule ["hm"] ["home-manager" "users" user])
            inputs.impermanence.nixosModules.impermanence
            inputs.sops-nix.nixosModules.sops
          ]
          ++ lib.optionals (host == "laptop") [
            inputs.nixos-hardware.nixosModules.dell-xps-13-9343
          ];
      }
    else
      inputs.home-manager.lib.homeManagerConfiguration {
        inherit extraSpecialArgs;
        pkgs = import inputs.nixpkgs {
          config.allowUnfree = true;
        };

        modules = [
          inputs.nix-index-database.hmModules.nix-index
          ./${host}/home.nix # host specific home-manager configuration
          ../overlays
          ../home-manager
          ../modules/home-manager
        ];
      };
in {
  vm = mkHost "vm";
  desktop = mkHost "desktop";
  laptop = mkHost "laptop";
}
