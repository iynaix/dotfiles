# patches to be applied to nixpkgs
{
  flake.nixosModules.core = _: {
    nixpkgs-patcher = {
      enable = true;

      settings.patches = [
        # orca-slicer 2.3.2-dev
        # https://github.com/NixOS/nixpkgs/pull/480799
        ./orca-slicer-2.3.2.patch
      ];
    };
  };
}
