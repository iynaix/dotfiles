# better repl with preloaded functions and libs already loaded
# https://bmcgee.ie/posts/2023/01/nix-and-its-slow-feedback-loop/#how-you-should-use-the-repl
{
  # host is passed down from the nrepl via a --arg argument, defaulting to the current host
  host ? "desktop",
  ...
}: let
  user = "iynaix";
  flake = builtins.getFlake (toString ./.);
  lib = flake.inputs.nixpkgs.lib;
in rec {
  inherit (flake) inputs;
  inherit (flake.inputs) nixpkgs;
  inherit flake lib host user;

  # default host
  c = flake.nixosConfigurations.${host}.config;
  co = c.iynaix-nixos;
  hm = c.home-manager.users.${user};
  hmo = hm.iynaix;
  pkgs = flake.nixosConfigurations.${host}.pkgs;

  desktop = flake.nixosConfigurations.desktop.config;
  desktopo = desktop.iynaix-nixos;
  desktopHm = desktop.home-manager.users.${user};
  desktopHmo = desktopHm.iynaix;

  laptop = flake.nixosConfigurations.laptop.config;
  laptopo = laptop.iynaix-nixos;
  laptopHm = laptop.home-manager.users.${user};
  laptopHmo = laptopHm.iynaix;

  vm = flake.nixosConfigurations.vm.config;
  vmo = vm.iynaix-nixos;
  vmHm = vm.home-manager.users.${user};
  vmHmo = vmHm.iynaix;

  # your code here
}
