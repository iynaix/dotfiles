{
  lib,
  callPackage,
  mpvScripts,
}:
let
  source = (callPackage ./generated.nix { }).mpv-subsearch;
in
mpvScripts.buildLua (
  source
  // {
    version = "0-unstable-${source.date}";

    dontBuild = true;

    scriptPath = "sub-search.lua";

    meta = {
      description = "Search for a phrase in subtitles and skip to it";
      homepage = "https://github.com/kelciour/mpv-scripts";
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
