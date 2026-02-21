{
  config,
  inputs,
  ...
}:
let
  mkNixos =
    host:
    {
      system ? "x86_64-linux",
      isVm ? false,
      user ? "iynaix",
      extraConfig ? { },
    }:
    inputs.nixpkgs-patcher.lib.nixosSystem {
      inherit system;

      nixpkgsPatcher.inputs = inputs; # for nixpkgs-patcher to patch

      modules = [
        {
          config.custom.constants = rec {
            inherit host isVm user;
            isLaptop = host == "xps" || host == "framework";
            projects = "/persist/home/${user}/projects";
            dots = "${projects}/dotfiles";
          };
        }
        config.flake.nixosModules."host-${host}"
        config.flake.nixosModules.core
        inputs.hjem.nixosModules.default
        inputs.nix-index-database.nixosModules.nix-index
        inputs.noctalia.nixosModules.default
        inputs.impermanence.nixosModules.impermanence
        inputs.sops-nix.nixosModules.sops
        extraConfig
      ];
    };
  mkVm = host: mkNixosArgs: mkNixos host (mkNixosArgs // { isVm = true; });
in
{
  flake.nixosConfigurations = {
    desktop = mkNixos "desktop" { };
    framework = mkNixos "framework" { };
    xps = mkNixos "xps" { };
    # VMs from config
    vm = mkVm "vm" { };
    # hyprland can be used within a VM on AMD
    vm-hyprland = mkVm "vm" { };
    # create VMs for each host configuration, build using
    # nixos-rebuild build-vm --flake .#desktop-vm
    desktop-vm = mkVm "desktop" { };
    framework-vm = mkVm "framework" { };
    xps-vm = mkVm "xps" { };
  };
}
