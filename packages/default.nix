{pkgs, ...}: {
  nixpkgs.overlays = [
    (
      self: super: {
        pkgs-iynaix = {
          # mpv plugins
          mpv-chapterskip = pkgs.callPackage ./mpv-chapterskip.nix {};
          mpv-deletefile = pkgs.callPackage ./mpv-deletefile.nix {};
          # mpv-modernx = (pkgs.callPackage ./mpv-modernx.nix {});
          mpv-nextfile = pkgs.callPackage ./mpv-nextfile.nix {};
          mpv-sub-select = pkgs.callPackage ./mpv-sub-select.nix {};
          mpv-subsearch = pkgs.callPackage ./mpv-subsearch.nix {};
          mpv-thumbfast-osc = pkgs.callPackage ./mpv-thumbfast-osc.nix {};

          trimage = pkgs.callPackage ./trimage.nix {
            inherit (pkgs.qt5) wrapQtAppsHook;
          };

          vv = pkgs.callPackage ./vv.nix {};
        };
      }
    )
  ];
}
