{
  lib,
  callPackage,
  mpvScripts,
}:
let
  source = (callPackage ./generated.nix { }).mpv-nextfile;
in
mpvScripts.buildLua (
  source
  // {
    version = "0-unstable-${source.date}";

    dontBuild = true;

    scriptPath = "nextfile.lua";

    meta = {
      description = "Force open next or previous file in the currently playing files directory";
      homepage = "https://github.com/jonniek/mpv-nextfile";
      license = lib.licenses.unlicense;
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
