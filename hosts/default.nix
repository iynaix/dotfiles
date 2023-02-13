{ lib, inputs, nixpkgs, home-manager, user, theme, hyprland, ... }:

let
  system = "x86_64-linux";
  vmInfo = {
    hostName = "vm";
    monitor1 = "Virtual-1";
  };
  desktopInfo = {
    hostName = "desktop";
    monitor1 = "DP-2";
    monitor2 = "DP-0.8";
    monitor3 = "HDMI-0";
  };
  laptopInfo = {
    hostName = "laptop";
    monitor1 = "eDP-1";
  };
in {
  vm = lib.nixosSystem {
    inherit system;

    specialArgs = {
      inherit system user;
      host = vmInfo;
    };

    modules = [
      ./configuration.nix # shared nixos configuration across all hosts
      ./vm # vm specific configuration, including hardware

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit user theme;
          host = vmInfo;
        };
        home-manager.users.${user} = {
          imports = [ (import ./home.nix) ] ++ [ (import ./vm/home.nix) ];
        };
      }
    ];
  };
  desktop = lib.nixosSystem {
    inherit system;

    specialArgs = {
      inherit system user;
      host = desktopInfo;
    };

    modules = [
      ./configuration.nix # shared nixos configuration across all hosts
      ./desktop # desktop specific configuration, including hardware

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit user theme;
          host = desktopInfo;
        };
        home-manager.users.${user} = {
          imports = [ (import ./home.nix) ] ++ [ (import ./desktop/home.nix) ];
        };
      }
    ];
  };
  laptop = lib.nixosSystem {
    inherit system;

    specialArgs = {
      inherit system user;
      host = laptopInfo;
    };

    modules = [
      ./configuration.nix # shared nixos configuration across all hosts
      ./laptop # desktop specific configuration, including hardware

      home-manager.nixosModules.home-manager
      {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = {
          inherit user theme;
          host = laptopInfo;
        };
        home-manager.users.${user} = {
          imports = [ (import ./home.nix) ] ++ [ (import ./laptop/home.nix) ];
        };
      }
    ];
  };
}
