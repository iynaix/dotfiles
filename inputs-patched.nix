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
  ];

  wrappers = [
    # expose options used to build each wrapped package
    ./patches/nix-wrappers-expose-options.patch

    # feat(wrapperModules.umbriel): init
    # https://github.com/nix-community/nix-wrapper-modules/pull/672
    (patcher.fetchpatch {
      url = "https://github.com/nix-community/nix-wrapper-modules/commit/3dba331ec372c3094d8718ff4f9b116949750fe9.patch";
      hash = "sha256-uc4ntD11zDkkRy0V/16vJbwzwP9FvqeAGPbPFCcNIOY=";
    })
  ];
}
