{
  inputs,
  lib,
  system,
  self,
  ...
}:
let
  # access to nixpkgs-stable
  nixpkgsStable = _: prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (prev.pkgs.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };

  # misc patches to packages in pkgs
  pkgsPatches = _: prev: {
    # nixos-small logo looks like ass
    fastfetch = prev.fastfetch.overrideAttrs (o: {
      patches = (o.patches or [ ]) ++ [ ../patches/fastfetch-nixos-old-small.patch ];
    });

    # fix nix package count for nitch
    nitch = prev.nitch.overrideAttrs (o: {
      patches = (o.patches or [ ]) ++ [ ../patches/nitch-nix-pkgs-count.patch ];
    });
  };

  # add flake.packages as pkgs.custom
  pkgsCustom = _: _prev: {
    # use the same patched inputs.nixpkgs as the rest of nixosConfiguration
    custom =
      let
        patchedPkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      in
      inputs.lamina.lib.mkPackages patchedPkgs [ ../modules ] {
        # lib already has .custom
        inherit inputs lib self;
      };
  };
in
{
  nixpkgs.overlays = [
    pkgsPatches
    pkgsCustom
    nixpkgsStable
  ];
}
