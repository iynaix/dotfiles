# NOTE: file is not named inputs.nix as that causes tack to ignore the .tack directory!

args:
let
  # inputs from tack
  unpatchedInputs = (import ./.tack) {
    overrides = args.tackOverrides or { };
  };

  patcher = unpatchedInputs.nixpkgs.legacyPackages.x86_64-linux.callPackage ./patcher.nix { };
in
patcher.patch unpatchedInputs {
  nixpkgs = [
    # awakened poe trade command line args
    # https://github.com/NixOS/nixpkgs/pull/496108
    (patcher.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/commit/7cc9882513f2cc5bd3355abd74ade48b5db6d5e4.patch";
      hash = "sha256-BMXkKvxWUsHtkDETt2v1m0MWzN2I5VVHy5m8yDUIKP4=";
    })
  ];

  wrappers = [
    # expose options used to build each wrapped package
    ./patches/nix-wrappers-expose-options.patch

    # reload mango config after rebuild
    # https://github.com/BirdeeHub/nix-wrapper-modules/pull/577
    (patcher.fetchpatch {
      url = "https://github.com/BirdeeHub/nix-wrapper-modules/commit/bfb0227977e1f5d77ed0ded496951fc317d7ed7e.patch";
      hash = "sha256-FsntoBr32EXmBdHvICisRMcWMzxqTXYCyviyFHDbYPg=";
    })

    # hyprland module
    # https://github.com/BirdeeHub/nix-wrapper-modules/pull/567
    (patcher.fetchpatch {
      url = "https://github.com/BirdeeHub/nix-wrapper-modules/commit/fa67e918488fedaec413316a8e3db8040a632e3a.patch";
      hash = "sha256-muNSLW2wCF0k/PbcfgRElxC1uY3YWwL8LqrwGorjeGk=";
    })

  ];
}
