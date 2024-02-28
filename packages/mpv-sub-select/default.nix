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

    scriptPath = "sub-select.lua";
    passthru.scriptName = "sub-select.lua";

    meta = {
      description = "Automatically skip chapters based on title";
      homepage = "https://github.com/CogentRedTester/mpv-sub-select";
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
