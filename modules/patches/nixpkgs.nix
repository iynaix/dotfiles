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

          # awakened poe trade command line args
          # https://github.com/NixOS/nixpkgs/pull/496108
          (pkgs.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/commit/7cc9882513f2cc5bd3355abd74ade48b5db6d5e4.patch";
            hash = "sha256-BMXkKvxWUsHtkDETt2v1m0MWzN2I5VVHy5m8yDUIKP4=";
          })

          # zfs_unstable: 2.4.0 -> 2.4.1
          (pkgs.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/pull/496444.patch";
            hash = "sha256-FeIpa+bhmvOO8FUKJg7cXWh7iM3deFLlYV3bvxSzRyI=";
          })
        ];
      };
    };
}
