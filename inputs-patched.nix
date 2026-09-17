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
    # always allow unfree, i dgaf
    ./patches/allow-unfree.patch

    # fix noctalia icon resolver because XDG_DATA_DIRS is not properly set
    ./patches/noctalia-fix-icon-resolver.patch

    # nixos/noctalia-greeter: add passwordlessSyncUsers option
    # https://github.com/NixOS/nixpkgs/pull/563958
    (patcher.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/commit/79b249f686716776d8fcbbd7802dd62e6b65caa8.patch";
      hash = "sha256-8Dwdy9i0FYd8G0gAWNgoOB403zsr8pS+OPqtXtX78Do=";
    })

    # nixos/noctalia-greeter: support services.displayManager.defaultSession
    # https://github.com/NixOS/nixpkgs/pull/560749
    (patcher.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/commit/ad0260f3890976460e317f352b97a3ed98c7a59d.patch";
      hash = "sha256-lkfMfQfeSCi/+fLo4hNdNN7eyh1cZS5pXB6cRjqH/Uo=";
    })

    # nixos/noctalia-greeter: support autologin
    # https://github.com/NixOS/nixpkgs/pull/560780
    (patcher.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/commit/0fa542d22aa91fa81c3b638e5350dafe6eb872f1.patch";
      hash = "sha256-4uvVEpN8Mckc8zibc+ExhFPNuL67vKJEVC2BUfbUodg=";
    })

    # swayimg 5.6
    # https://github.com/NixOS/nixpkgs/pull/561142
    (patcher.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/commit/6f7a42550ab818811302a4ce21efb94c06543239.patch";
      hash = "sha256-Gsa1O4KPuXeJjz7CCJH1tjzsdRBTMYk1rOFBAZYDr4A=";
    })

    # awakened-poe-trade: add commandLineArgs
    # https://github.com/NixOS/nixpkgs/pull/496108
    (patcher.fetchpatch {
      url = "https://github.com/NixOS/nixpkgs/commit/7cc9882513f2cc5bd3355abd74ade48b5db6d5e4.patch";
      hash = "sha256-BMXkKvxWUsHtkDETt2v1m0MWzN2I5VVHy5m8yDUIKP4=";
    })
  ];

  sops-nix = [
    # fix go 1.25 EOL
    # https://github.com/Mic92/sops-nix/pull/984
    (patcher.fetchpatch {
      url = "https://github.com/Mic92/sops-nix/commit/81630c5d814c38e6bf7b23888b53d8dad595e228.patch";
      hash = "sha256-j/mrIzTyZyURzOSleAPatxY3AqgRHeFmZNzvpsl0OT8=";
    })
  ];

  wrappers = [
    # expose options used to build each wrapped package
    ./patches/nix-wrappers-expose-options.patch

    # hyprland module
    # https://github.com/BirdeeHub/nix-wrapper-modules/pull/567
    (patcher.fetchpatch {
      url = "https://github.com/BirdeeHub/nix-wrapper-modules/commit/94794a07e384edb6ee4506be4d8a731d73c8eafc.patch";
      hash = "sha256-SLmLyhJ1rA4A3EMHJxqDBlgE32k8NUHRINNkWvuDxMw=";
    })

    # noctalia module
    # https://github.com/BirdeeHub/nix-wrapper-modules/pull/598
    (patcher.fetchpatch {
      url = "https://github.com/BirdeeHub/nix-wrapper-modules/commit/8dc6e5fa91c39033b6a8613b2ba5cfcc72728792.patch";
      hash = "sha256-Lo/wvbqEv5DoFQ/FwqXTTUn+Bfck/V6M3EfRG5jdTrY=";
    })
  ];

  umbriel = [
    # add opaque_fullscreen option
    # https://github.com/noctalia-dev/umbriel/pull/242
    (patcher.fetchpatch {
      url = "https://github.com/noctalia-dev/umbriel/compare/bb9ed295194480de3004ee4ff61e0811c5250420~1..9e8752d0bb388ab9c2026a100cec59ee9af77fee.patch";
      hash = "sha256-GsQ6al1ZUtzOwW1ES8nF9E6OrQXtFwiN2NjIm/zW5jM=";
    })
  ];
}
