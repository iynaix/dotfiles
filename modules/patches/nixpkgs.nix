{
  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      nixpkgs-patcher = {
        enable = true;

        settings.patches = [
          # awakened poe trade command line args
          # https://github.com/NixOS/nixpkgs/pull/496108
          (pkgs.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/commit/7cc9882513f2cc5bd3355abd74ade48b5db6d5e4.patch";
            hash = "sha256-BMXkKvxWUsHtkDETt2v1m0MWzN2I5VVHy5m8yDUIKP4=";
          })

          # update rclip to v3
          # https://github.com/NixOS/nixpkgs/pull/522443
          (pkgs.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/commit/97df686cc72ac8173c4246f58c96b7886febbaa4.patch";
            hash = "sha256-EGORJLTxSWqeqIxpFYMOOzTpTuvs5ZqKDz34pktdMU0=";
          })
        ];
      };
    };
}
