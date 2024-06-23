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

    scriptPath = "main.lua";
    passthru.scriptName = "main.lua";

    meta = {
      description = "An mpv plugin for cutting videos incredibly quickly.";
      homepage = "https://github.com/familyfriendlymikey/mpv-cut";
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
