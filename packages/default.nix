{pkgs, ...}: let
  callPackageWithSources = file: args:
    pkgs.callPackage file (args
      // {
        sources = import ../_sources/generated.nix {inherit (pkgs) fetchFromGitHub fetchurl fetchgit dockerTools;};
      });
in {
  # mpv plugins
  mpv-chapterskip = callPackageWithSources ./mpv-chapterskip.nix {};
  mpv-deletefile = callPackageWithSources ./mpv-deletefile.nix {};
  mpv-modernx = callPackageWithSources ./mpv-modernx.nix {};
  mpv-nextfile = callPackageWithSources ./mpv-nextfile.nix {};
  mpv-sub-select = callPackageWithSources ./mpv-sub-select.nix {};
  mpv-subsearch = callPackageWithSources ./mpv-subsearch.nix {};
  mpv-thumbfast-osc = callPackageWithSources ./mpv-thumbfast-osc.nix {};

  trimage = pkgs.callPackage ./trimage.nix {
    inherit (pkgs.qt5) wrapQtAppsHook;
  };

  vv = callPackageWithSources ./vv.nix {};
}
