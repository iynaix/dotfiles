{ pkgs, ... }:
let
  inherit (pkgs) lib callPackage;
  inherit (pkgs.mpvScripts) buildLua;
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

  distro-grub-themes-nixos = callPackage ./distro-grub-themes-nixos { };

  hyprnstack = callPackage ./hyprnstack { };

  # mpv plugins
  mpv-deletefile = w pkgs.mpvScripts.callPackage ./mpv-deletefile { inherit buildLua; };
  mpv-dynamic-crop =
    assert (
      lib.assertMsg (
        !lib.hasAttr "dynamic-crop" pkgs.mpvScripts
      ) "dynamic-crop: dynamic-crop is in nixpkgs"
    );
    (w pkgs.mpvScripts.callPackage ./mpv-dynamic-crop { inherit buildLua; });
  mpv-modernx = w pkgs.mpvScripts.callPackage ./mpv-modernx { inherit buildLua; };
  mpv-nextfile = w pkgs.mpvScripts.callPackage ./mpv-nextfile { inherit buildLua; };
  mpv-sub-select = w pkgs.mpvScripts.callPackage ./mpv-sub-select { inherit buildLua; };
  mpv-subsearch = w pkgs.mpvScripts.callPackage ./mpv-subsearch { inherit buildLua; };
  mpv-thumbfast-osc = w pkgs.mpvScripts.callPackage ./mpv-thumbfast-osc { inherit buildLua; };

  rofi-themes = w callPackage ./rofi-themes { };

  scope-tui =
    assert (lib.assertMsg (!lib.hasAttr "scope-tui" pkgs) "scope-tui: scope-tui is in nixpkgs");
    callPackage ./scope-tui { };

  vv =
    assert (lib.assertMsg (!lib.hasAttr "vv" pkgs) "vv: vv is in nixpkgs");
    (w callPackage ./vv { });
}
