{ self, ... }:
{
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

  flake.modules.nixos.core = {
    # add the patches to the overlays
    nixpkgs.overlays = [
      self.overlays.pkgsPatches
    ];
  };
}
