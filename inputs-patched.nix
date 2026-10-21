# NOTE: file is not named inputs.nix as that causes tack to ignore the .tack directory!

unpatchedInputs:
let
  patcher = unpatchedInputs.nixpkgs.legacyPackages.x86_64-linux.callPackage ./patcher.nix { };
in
patcher.patch unpatchedInputs {
  # for multiple commits:
  # https://github.com/USER/REPO/compare/EARLIER_OR_TOP_COMMIT~1..LATEST_OR_BOTTOM_COMMIT.patch

  nixpkgs = [
    # always allow unfree, i dgaf
    ./patches/allow-unfree.patch

    # nixos/noctalia-greeter: support autologin
    # https://github.com/NixOS/nixpkgs/pull/560780
    (patcher.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/commit/477a86df848b03eef447a06f0fd505ed2f10375d.patch";
      hash = "sha256-GeCd7EPZwvP79tc9Ss2hD/WIOfq/7XSo27WLn/z+2HQ=";
    })

    # awakened-poe-trade: add commandLineArgs
    # https://github.com/NixOS/nixpkgs/pull/496108
    (patcher.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/commit/7cc9882513f2cc5bd3355abd74ade48b5db6d5e4.patch";
      hash = "sha256-BMXkKvxWUsHtkDETt2v1m0MWzN2I5VVHy5m8yDUIKP4=";
    })

    # rclip: 4.0.1 -> 4.0.4
    # https://github.com/NixOS/nixpkgs/pull/576179
    (patcher.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/commit/6288fe6eafef879d0b5817146d66ca9a6bda704c.patch";
      hash = "sha256-gSkEFEsawR9YQuqSRqFuHB/LAJAS3cCYj+BA3Da22Jk=";
    })

    # rusty-path-of-building: 0.2.18 -> 0.3.1
    # https://github.com/NixOS/nixpkgs/pull/577137
    (patcher.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/commit/0a1795b061a1104f1fdb21adab172cb95712e4ff.patch";
      hash = "sha256-OM0XMhEj32lyedVMJGnAdaoW+TZpsEJ8iBMZw31FZ2A=";
    })
  ];

  wrappers = [
    # expose options used to build each wrapped package
    ./patches/nix-wrappers-expose-options.patch

    # noctalia module
    # https://github.com/BirdeeHub/nix-wrapper-modules/pull/598
    (patcher.fetchpatch {
      url = "https://github.com/BirdeeHub/nix-wrapper-modules/commit/8dc6e5fa91c39033b6a8613b2ba5cfcc72728792.patch";
      hash = "sha256-Lo/wvbqEv5DoFQ/FwqXTTUn+Bfck/V6M3EfRG5jdTrY=";
    })
  ];
}
