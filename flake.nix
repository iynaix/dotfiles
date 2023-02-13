{
  description = "iynaix's dotfiles managed via nixos and home-manager";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = { # Official Hyprland flake
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, home-manager, hyprland, ... }:
    let
      user = "iynaix";
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
      nixosConfigurations = (import ./hosts {
        inherit (nixpkgs) lib;
        inherit inputs nixpkgs home-manager user theme hyprland;
      });
    };
}
