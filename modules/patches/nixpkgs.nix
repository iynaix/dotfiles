# patches to be applied to nixpkgs
{
  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      nixpkgs-patcher = {
        enable = true;

        settings.patches = [
          # orca-slicer 2.3.2-dev
          # https://github.com/NixOS/nixpkgs/pull/480799
          ./orca-slicer-2.3.2.patch

          # zfs_unstable: 2.4.0 -> 2.4.1
          (pkgs.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/pull/496444.patch";
            hash = "sha256-FeIpa+bhmvOO8FUKJg7cXWh7iM3deFLlYV3bvxSzRyI=";
          })
        ];
      };
    };
}
