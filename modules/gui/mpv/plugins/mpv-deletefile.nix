{ self, ... }:
let
  drv =
    {
      sources,
      lib,
      mpvScripts,
    }:
    let
      source = sources.mpv-deletefile;
    in
    mpvScripts.buildLua (
      source
      // {
        version = "0-unstable-${source.date}";

        dontBuild = true;

        scriptPath = "delete_file.lua";

        meta = {
          description = "Deletes files played through mpv";
          homepage = "https://github.com/zenyd/mpv-scripts";
          license = lib.licenses.gpl3;
          maintainers = [ lib.maintainers.iynaix ];
        };
      }
    );
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.mpv-deletefile = pkgs.callPackage drv {
        sources = self.libCustom.nvFetcherSources pkgs;
      };
    };
}
