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

  # custom tela built with catppucin variant colors
  tela-dynamic-icon-theme = callPackage ./tela-dynamic-icon-theme { };

  distro-grub-themes-nixos = callPackage ./distro-grub-themes-nixos { };

  hyprnstack = w callPackage ./hyprnstack { };

  # mpv plugins
  mpv-cut = w pkgs.mpvScripts.callPackage ./mpv-cut { };
  mpv-deletefile = w pkgs.mpvScripts.callPackage ./mpv-deletefile { };
  mpv-nextfile = w pkgs.mpvScripts.callPackage ./mpv-nextfile { };
  mpv-smartskip = w pkgs.mpvScripts.callPackage ./mpv-smartskip { };
  mpv-sub-select = w pkgs.mpvScripts.callPackage ./mpv-sub-select { };
  mpv-subsearch = w pkgs.mpvScripts.callPackage ./mpv-subsearch { };

  # for nixos-rebuild
  hsw = callPackage ./hsw { };
  nsw = callPackage ./nsw { };

  rofi-themes = w callPackage ./rofi-themes { };

  vv =
    assert (lib.assertMsg (!lib.hasAttr "vv" pkgs) "vv: vv is in nixpkgs");
    (w callPackage ./vv { });
}
