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

    scriptPath = "dynamic-crop.lua";
    passthru.scriptName = "dynamic-crop.lua";

    meta = {
      description = ''Script to "cropping" dynamically, hard-coded black bars detected with lavfi-cropdetect filter for Ultra Wide Screen or any screen (Smartphone/Tablet).'';
      homepage = "https://github.com/Ashyni/mpv-scripts";
      license = lib.licenses.mit;
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
