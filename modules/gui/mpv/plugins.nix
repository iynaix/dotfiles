{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        mpv-cut = pkgs.callPackage ../../../packages/mpv-cut { };
        mpv-deletefile = pkgs.callPackage ../../../packages/mpv-deletefile { };
        mpv-nextfile = pkgs.callPackage ../../../packages/mpv-nextfile { };
        mpv-sub-select = pkgs.callPackage ../../../packages/mpv-sub-select { };
        mpv-subsearch = pkgs.callPackage ../../../packages/mpv-subsearch { };
      };
    };
}
