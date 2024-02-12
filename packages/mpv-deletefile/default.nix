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

    scriptPath = "delete_file.lua";
    passthru.scriptName = "delete_file.lua";

    meta = {
      description = "Deletes files played through mpv";
      homepage = "https://github.com/zenyd/mpv-scripts";
      license = lib.licenses.gpl3;
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
