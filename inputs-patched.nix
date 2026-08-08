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

    # build zfs for linux 7.1, no issues according to a core dev
    # https://github.com/openzfs/zfs/issues/18760#issuecomment-4919127088
    ./patches/zfs_unstable-linux-7_1.patch
  ];

  wrappers = [
    # expose options used to build each wrapped package
    ./patches/nix-wrappers-expose-options.patch

    # support literal regex props for niri kdl
    # https://github.com/BirdeeHub/nix-wrapper-modules/pull/581
    (patcher.fetchpatch {
      url = "https://github.com/BirdeeHub/nix-wrapper-modules/commit/fa6d6ed733f6ab9c16cb16cefab8ea1bb7ac68d2.patch";
      hash = "sha256-vJodXTWo++ukNWgBVfb2+XbTMoTfee0U3Q7Vur32LzM=";
    })

    # fix fish abbreviation generation, command default
    # https://github.com/BirdeeHub/nix-wrapper-modules/pull/583
    (patcher.fetchurl {
      url = "https://github.com/BirdeeHub/nix-wrapper-modules/compare/c0988332083951d97f808212554dfef7456c6a91~1..3eaadc1bf0dac4b0e70ac638022dc13cff980b41.patch";
      hash = "sha256-mlAnlW45vJ4YmiD4IS1ehWC8k/S02DBsLUZ0TTJ/fRQ=";
    })

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
