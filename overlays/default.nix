{ inputs, ... }:
let
  # include nixpkgs stable
  overlayStable = _: prev: {
    stable = import inputs.nixpkgs-stable {
      inherit (prev.pkgs) system;
      config.allowUnfree = true;
    };
  };
  # include custom packages
  overlayCustom = _: prev: {
    custom =
      (prev.custom or { })
      // (import ../packages {
        inherit (prev) pkgs;
        inherit inputs;
      });
  };
  overlayPatches = _: prev: {
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

    # fix some ugly styling for nemo in tokyonight
    tokyonight-gtk-theme = prev.tokyonight-gtk-theme.overrideAttrs (o: {
      patches = (o.patches or [ ]) ++ [ ./tokyonight-style.patch ];
    });
  };
in
{
  nixpkgs.overlays = [
    overlayStable
    overlayCustom
    overlayPatches
  ];
}
