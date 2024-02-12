{
  lib,
  buildLua,
  source,
}:
buildLua (
  source
  // {
    dontBuild = true;

    scriptPath = "sub-select.lua";
    passthru.scriptName = "sub-select.lua";
  }
  // {
    version = "unstable-${source.date}";

    meta = {
      description = "Automatically skip chapters based on title";
      homepage = "https://github.com/CogentRedTester/mpv-sub-select";
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
