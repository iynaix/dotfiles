{ lib, inputs, nixpkgs, home-manager, user, hyprland, hyprwm-contrib, nixos-hardware, ... }:
let
  createHost = { hostName }: lib.nixosSystem rec {
    system = "x86_64-linux";

    specialArgs = {
      inherit user;
      host = hostName;
    };

    modules = [
      ./configuration.nix # shared nixos configuration across all hosts
      ./${hostName} # host specific configuration, including hardware
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          users.${user} = {
            imports = [ inputs.hyprland.homeManagerModules.default ];
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
        nixpkgs.overlays = (import ../overlays) ++ [
          (self: super: {
            hyprwm-contrib-packages = hyprwm-contrib.packages.${system};
          })
        ];
      }
      inputs.impermanence.nixosModules.impermanence
    ] ++ lib.optional (hostName == "laptop") nixos-hardware.nixosModules.dell-xps-13-9343;
  };
in
{
  vm = createHost { hostName = "vm"; };
  desktop = createHost { hostName = "desktop"; };
  laptop = createHost { hostName = "laptop"; };
}
