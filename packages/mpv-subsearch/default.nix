{
  lib,
  buildLua,
  source,
}:
buildLua (
  source
  // {
    version = "0-unstable-${source.date}";

    dontBuild = true;

    scriptPath = "sub-search.lua";
    passthru.scriptName = "sub-search.lua";

    meta = {
      description = "Search for a phrase in subtitles and skip to it";
      homepage = "https://github.com/kelciour/mpv-scripts";
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
