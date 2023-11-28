{
  inputs,
  pkgs,
  ...
}: let
  lib = pkgs.lib;
  # use latest stable rust
  rustPlatform = let
    toolchain = inputs.fenix.packages.${pkgs.system}.stable.toolchain;
  in
    pkgs.makeRustPlatform {
      cargo = toolchain;
      rustc = toolchain;
    };
  # injects a source parameter from nvfetcher
  # adapted from viperML's config
  # https://github.com/viperML/dotfiles/blob/master/packages/default.nix
  w = _callPackage: path: extraOverrides: let
    sources = pkgs.callPackages (path + "/generated.nix") {};
    firstSource = builtins.head (builtins.attrValues sources);
  in
    _callPackage (path + "/default.nix") (extraOverrides
      // {source = lib.filterAttrs (k: v: !(lib.hasPrefix "override" k)) firstSource;});
in {
  # rust dotfiles utils
  dotfiles-utils =
    pkgs.callPackage ./dotfiles-utils {inherit rustPlatform;};

  # mpv plugins
  mpv-anime4k = pkgs.callPackage ./mpv-anime4k {};
  mpv-deletefile = w pkgs.callPackage ./mpv-deletefile {};
  mpv-dynamic-crop = w pkgs.callPackage ./mpv-dynamic-crop {};
  mpv-modernx = w pkgs.callPackage ./mpv-modernx {} {};
  mpv-nextfile = w pkgs.callPackage ./mpv-nextfile {};
  mpv-sub-select = w pkgs.callPackage ./mpv-sub-select {};
  mpv-subsearch = w pkgs.callPackage ./mpv-subsearch {};
  mpv-thumbfast-osc = w pkgs.callPackage ./mpv-thumbfast-osc {};

  vv = w pkgs.callPackage ./vv {};
}
