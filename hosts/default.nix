{ lib, inputs, nixpkgs, home-manager, user, hyprland, ... }:

let system = "x86_64-linux";
in {
  vm = lib.nixosSystem {
    inherit system;

    modules = [
      ./configuration.nix # shared nixos configuration across all hosts
      ./vm # vm specific configuration, including hardware

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.users.${user} = { imports = [ ./vm/home.nix ]; };
      }
    ];
  };
}
