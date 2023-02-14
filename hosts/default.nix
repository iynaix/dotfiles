{ lib, inputs, nixpkgs, home-manager, user, hyprland, ... }:

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
  # cappuccin mocha
  theme = {
    base = "#1e1e2e";
    mantle = "#181825";
    crust = "#11111b";

    text = "#cdd6f4";
    subtext0 = "#a6adc8";
    subtext1 = "#bac2de";

    surface0 = "#313244";
    surface1 = "#45475a";
    surface2 = "#585b70";

    overlay0 = "#6c7086";
    overlay1 = "#7f849c";
    overlay2 = "#9399b2";

    blue = "#89b4fa";
    lavender = "#b4befe";
    sapphire = "#74c7ec";
    sky = "#89dceb";
    teal = "#94e2d5";
    green = "#a6e3a1";
    yellow = "#f9e2af";
    peach = "#fab387";
    maroon = "#eba0ac";
    red = "#f38ba8";
    mauve = "#cba6f7";
    pink = "#f5c2e7";
    flamingo = "#f2cdcd";
    rosewater = "#f5e0dc";

    transparent = "#FF00000";
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
