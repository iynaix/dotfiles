# better repl with preloaded functions and libs already loaded
# https://bmcgee.ie/posts/2023/01/nix-and-its-slow-feedback-loop/#how-you-should-use-the-repl
{
  # host is passed down from the nrepl via a --arg argument, defaulting to the current host
  host ? "desktop",
  ...
}:
let
  user = "elias-ainsworth";
  flake = builtins.getFlake (toString ./.);
in
rec {
  inherit (flake) inputs lib self;
  inherit (flake.inputs) nixpkgs;
  inherit flake host user;

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

  x1c = flake.nixosConfigurations.x1c.config;
  x1co = x1c.custom;
  x1cHm = x1c.hm;
  x1cHmo = x1cHm.custom;

  t520 = flake.nixosConfigurations.t520.config;
  t520o = t520.custom;
  t520Hm = t520.hm;
  t520Hmo = t520Hm.custom;

  t450 = flake.nixosConfigurations.t450.config;
  t450o = t450.custom;
  t450Hm = t450.hm;
  t450Hmo = t450Hm.custom;

  vm = flake.nixosConfigurations.vm.config;
  vmo = vm.custom;
  vmHm = vm.hm;
  vmHmo = vmHm.custom;

  # your code here
}
