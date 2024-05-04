# better repl with preloaded functions and libs already loaded
# https://bmcgee.ie/posts/2023/01/nix-and-its-slow-feedback-loop/#how-you-should-use-the-repl
{
  # host is passed down from the nrepl via a --arg argument, defaulting to the current host
  host ? "desktop",
  ...
}:
let
  user = "iynaix";
  flake = builtins.getFlake (toString ./.);
  inherit (flake.inputs.nixpkgs) lib;
in
rec {
  inherit (flake) inputs self;
  inherit (flake.inputs) nixpkgs;
  inherit
    flake
    lib
    host
    user
    ;

  # default host
  c = flake.nixosConfigurations.${host}.config;
  inherit (flake.nixosConfigurations.${host}) config;
  o = c.custom;
  inherit (c) hm;
  hmo = hm.custom;
  inherit (flake.nixosConfigurations.${host}) pkgs;

  desktop = flake.nixosConfigurations.desktop.config;
  desktopo = desktop.custom;
  desktopHm = desktop.hm;
  desktopHmo = desktopHm.custom;

  framework = flake.nixosConfigurations.framework.config;
  frameworko = framework.custom;
  frameworkHm = framework.hm;
  frameworkHmo = frameworkHm.custom;

  laptop = flake.nixosConfigurations.framework.config;
  laptopo = framework.custom;
  laptopHm = framework.hm;
  laptopHmo = frameworkHm.custom;

  vm = flake.nixosConfigurations.vm.config;
  vmo = vm.custom;
  vmHm = vm.hm;
  vmHmo = vmHm.custom;

  # your code here
}
