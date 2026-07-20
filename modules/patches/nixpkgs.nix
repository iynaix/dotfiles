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

          # build zfs for linux 7.1, no issues according to a core dev
          # https://github.com/openzfs/zfs/issues/18760#issuecomment-4919127088
          ./zfs_unstable-linux-7_1.patch

          # mango 15 requires scenefx 0.5
          # https://github.com/NixOS/nixpkgs/pull/539969
          # use fetchurl as files are renamed, fetchpatch breaks the application of the patch
          (pkgs.fetchurl {
            url = "https://github.com/NixOS/nixpkgs/compare/53f7fa3fe934c4b50716b17e544057a98c1fa0eb~1..60a465634381dccfbd76cb50903bfb1734f3c9bf.patch";
            hash = "sha256-42Fl/kXl963Rj7Fd9oo+/muIz2quMBTb5k75YcwK5co=";
          })

          # hyprland 0.56 (requires hyprutils patch above)
          (pkgs.fetchurl {
            url = "https://github.com/NixOS/nixpkgs/compare/035c487b7684e4a4f556462274c056f29b47d03e~1..2fc6f2ca6944dda22abe736cbd8e93c45fde5be2.patch";
            hash = "sha256-Qh8ArHN02VsmWa+IBRG3/qSwboTmB5ZMSXNcwf3CzsA=";
          })
        ];
      };
    };
}
