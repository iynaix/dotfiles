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
          pname = "mpv-subsearch";
          src = fetchFromGitHub {
            owner = "kelciour";
            repo = "mpv-scripts";
            rev = "9a5cda4fc8f0896cec27dca60a32251009c0e9c5";
            sha256 = "sha256-BRyKJeXWFhsCDKTUNKsp+yqYpP9mzbaZMviUFXyA308=";
          };

          version = "0-unstable-2019-01-24";

          dontBuild = true;

          scriptPath = "sub-search.lua";

          meta = {
            description = "Search for a phrase in subtitles and skip to it";
            homepage = "https://github.com/kelciour/mpv-scripts";
            maintainers = [ lib.maintainers.iynaix ];
          };
        };
    in
    {
      packages.mpv-subsearch = pkgs.callPackage drv { };
    };
}
