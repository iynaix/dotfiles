{ lib, inputs, nixpkgs, home-manager, user, hyprland, nixos-hardware, ... }:
let
  createHost = { hostName }: lib.nixosSystem {
    system = "x86_64-linux";

    specialArgs = {
      inherit user;
      host = hostName;
    };

    modules = [
      ./configuration.nix # shared nixos configuration across all hosts
      ./home.nix # shared configuration for home-manager across all hosts
      ./${hostName} # host specific configuration, including hardware
      home-manager.nixosModules.home-manager
      inputs.impermanence.nixosModules.impermanence
    ] ++ lib.optional (hostName == "laptop") nixos-hardware.nixosModules.dell-xps-13-9343;
  };
in
{
  vm = createHost { hostName = "vm"; };
  desktop = createHost { hostName = "desktop"; };
  laptop = createHost { hostName = "laptop"; };
}
