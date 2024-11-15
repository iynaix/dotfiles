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

    scriptPath = "scripts/SmartSkip.lua";

    meta = {
      description = "Automatically or manually skip opening, intro, outro, and preview, like never before. Jump to next file, previous file, and save your chapter changes!";
      homepage = "https://github.com/Eisa01/mpv-scripts";
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
