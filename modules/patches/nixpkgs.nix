{ self, ... }: {
  # misc patches to packages in pkgs
  flake.overlays.pkgsPatches = _: prev: {
    # nixos-small logo looks like ass
    fastfetch = prev.fastfetch.overrideAttrs (o: {
      patches = (o.patches or [ ]) ++ [ ./fastfetch-nixos-old-small.patch ];
    });

    # add default font to silence null font errors
    lsix = prev.lsix.overrideAttrs (o: {
      postFixup = /* sh */ ''
        substituteInPlace $out/bin/lsix \
          --replace-fail '#fontfamily=Mincho' 'fontfamily="JetBrainsMono-NF-Regular"'
        ${o.postFixup}
      '';
    });

    # fix nix package count for nitch
    nitch = prev.nitch.overrideAttrs (o: {
      patches = (o.patches or [ ]) ++ [ ./nitch-nix-pkgs-count.patch ];
    });
  };

  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      # add the patches to the overlays
      nixpkgs.overlays = [
        self.overlays.pkgsPatches
      ];

      nixpkgs-patcher = {
        enable = true;

        settings.patches = [
          # awakened poe trade command line args
          # https://github.com/NixOS/nixpkgs/pull/496108
          (pkgs.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/commit/7cc9882513f2cc5bd3355abd74ade48b5db6d5e4.patch";
            hash = "sha256-BMXkKvxWUsHtkDETt2v1m0MWzN2I5VVHy5m8yDUIKP4=";
          })

          # fix orca-slicer viewport due to glew
          # https://github.com/NixOS/nixpkgs/pull/530580/files
          (pkgs.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/commit/96add13bce8f664b92eeb528f56b2b7717d9de11.patch";
            hash = "sha256-KGjB47ZPhIHUyLM9HgOkSRxuKYw17GOn6P0AERlQoOA=";
          })
        ];
      };
    };
}
