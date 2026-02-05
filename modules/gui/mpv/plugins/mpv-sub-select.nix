{ self, ... }:
let
  drv =
    {
      sources,
      lib,
      mpvScripts,
    }:
    let
      source = sources.mpv-sub-select;
    in
    mpvScripts.buildLua (
      source
      // {
        version = "0-unstable-${source.date}";

        dontBuild = true;

        scriptPath = "sub-select.lua";

        meta = {
          description = "Automatically skip chapters based on title";
          homepage = "https://github.com/CogentRedTester/mpv-sub-select";
          maintainers = [ lib.maintainers.iynaix ];
        };
      }
    );
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.mpv-sub-select = pkgs.callPackage drv {
        sources = self.libCustom.nvFetcherSources pkgs;
      };
    };
}
