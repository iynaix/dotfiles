{ pkgs, ... }:
let
  inherit (pkgs) lib callPackage;
  # injects a source parameter from nvfetcher
  # adapted from viperML's config
  # https://github.com/viperML/dotfiles/blob/master/packages/default.nix
  w =
    _callPackage: path: extraOverrides:
    let
      sources = pkgs.callPackages (path + "/generated.nix") { };
      firstSource = lib.head (lib.attrValues sources);
    in
    _callPackage (path + "/default.nix") (
      extraOverrides // { source = lib.filterAttrs (k: _: !(lib.hasPrefix "override" k)) firstSource; }
    );
in
{
  # boutique rust packages
  dotfiles-utils = callPackage ./dotfiles-utils { };
  wfetch = callPackage ./wfetch { };

  distro-grub-themes-nixos = callPackage ./distro-grub-themes-nixos { };

  hyprnstack = callPackage ./hyprnstack { };

  # mpv plugins
  mpv-deletefile = w callPackage ./mpv-deletefile { };
  mpv-dynamic-crop = w callPackage ./mpv-dynamic-crop { };
  mpv-modernx = callPackage ./mpv-modernx {
    source = (callPackage ./mpv-modernx/generated.nix { }).mpv-modernx;
  };
  mpv-nextfile = w callPackage ./mpv-nextfile { };
  mpv-sub-select = w callPackage ./mpv-sub-select { };
  mpv-subsearch = w callPackage ./mpv-subsearch { };
  mpv-thumbfast-osc = w callPackage ./mpv-thumbfast-osc { };

  mpv-anime = w callPackage ./mpv-anime { };

  # custom version of pob with a .desktop entry, overwritten as a custom package
  # as the interaction with passthru is weird
  # https://github.com/NixOS/nixpkgs/blob/master/pkgs/games/path-of-building/default.nix
  path-of-building = w pkgs.qt6Packages.callPackage ./path-of-building { };

  rofi-themes = w callPackage ./rofi-themes { };

  vv =
    assert (lib.assertMsg (!lib.hasAttr "vv" pkgs) "vv: vv is in nixpkgs");
    w callPackage ./vv { };
}
