{
  lib,
  buildLua,
  source,
}:
buildLua (
  source
  // {
    version = "unstable-${source.date}";

    dontBuild = true;

    scriptPath = "player/lua/osc.lua";
    passthru.scriptName = "thumbfast-osc.lua";

    meta = {
      description = "High-performance on-the-fly thumbnailer for mpv";
      homepage = "https://github.com/po5/thumbfast/tree/vanilla-osc";
      license = lib.licenses.mpl20;
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
