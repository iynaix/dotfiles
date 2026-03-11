{
  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      nixpkgs-patcher = {
        enable = true;

        settings.patches = [
          # orca-slicer: 2.3.1 -> 2.3.2
          # https://github.com/NixOS/nixpkgs/pull/495746
          (pkgs.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/commit/c02a96a7e821e20ae008f41c940effae799d5359.patch";
            hash = "sha256-9VlOhHD2oM6X+xwVBSeQanD5syWHbIN2nH5tyHkdHJ8=";
          })

          # awakened poe trade command line args
          # https://github.com/NixOS/nixpkgs/pull/496108
          (pkgs.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/commit/7cc9882513f2cc5bd3355abd74ade48b5db6d5e4.patch";
            hash = "sha256-BMXkKvxWUsHtkDETt2v1m0MWzN2I5VVHy5m8yDUIKP4=";
          })
        ];
      };
    };
}
