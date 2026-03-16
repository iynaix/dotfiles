{
  perSystem =
    { pkgs, ... }:
    let
      drv =
        {
          lib,
          fetchFromGitHub,
          mpvScripts,
        }:
        mpvScripts.buildLua {
          pname = "mpv-cut";
          src = fetchFromGitHub {
            owner = "jonniek";
            repo = "mpv-nextfile";
            rev = "b8f7a4d6224876bf26724a9313a36e84d9ecfd81";
            sha256 = "sha256-Ad98iUbumhsudGwHcYEVTV6ye6KHj5fHAx8q90UQ2QM=";
          };

          version = "0-unstable-2023-11-22";

          dontBuild = true;

          scriptPath = "nextfile.lua";

          meta = {
            description = "Force open next or previous file in the currently playing files directory";
            homepage = "https://github.com/jonniek/mpv-nextfile";
            license = lib.licenses.unlicense;
            maintainers = [ lib.maintainers.iynaix ];
          };
        };
    in
    {
      packages.mpv-nextfile = pkgs.callPackage drv { };
    };
}
