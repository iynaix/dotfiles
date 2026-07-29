{
  description = "iynaix's dotfiles";

  outputs =
    { self, ... }@args:
    let
      # inputs from tack
      unpatchedInputs = (import ./.tack) {
        overrides = args.tackOverrides or { };
      };

      patcher = unpatchedInputs.nixpkgs.legacyPackages.x86_64-linux.callPackage ./patcher.nix { };

      inputs = patcher.patch unpatchedInputs {
        nixpkgs.patches = [
          # awakened poe trade command line args
          # https://github.com/NixOS/nixpkgs/pull/496108
          (patcher.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/commit/7cc9882513f2cc5bd3355abd74ade48b5db6d5e4.patch";
            hash = "sha256-BMXkKvxWUsHtkDETt2v1m0MWzN2I5VVHy5m8yDUIKP4=";
          })

          # build zfs for linux 7.1, no issues according to a core dev
          # https://github.com/openzfs/zfs/issues/18760#issuecomment-4919127088
          ./modules/patches/zfs_unstable-linux-7_1.patch

          # rclip 3.2.4
          (patcher.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/commit/db91871f276c5250dcfed88e413b6e469271e71a.patch";
            hash = "sha256-J5G0mnBB8uVAZAqJ8v2PzRovA6kCM0wOxMFp7YttyGI=";
          })
        ];
      };

      inherit (inputs.nixpkgs.lib.fileset) toList fileFilter;
      import-tree =
        path:
        toList (fileFilter (file: file.hasExt "nix" && !(inputs.nixpkgs.lib.hasPrefix "_" file.name)) path);
    in
    inputs.flake-parts.lib.mkFlake
      {
        inherit self inputs;
      }
      {
        imports = import-tree ./modules;

        flake.templates = import ./templates;
      };
}
