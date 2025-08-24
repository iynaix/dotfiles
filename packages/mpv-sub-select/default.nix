{
  lib,
  callPackage,
  mpvScripts,
}:
let
  source = (callPackage ./generated.nix { }).mpv-sub-select;
in
mpvScripts.buildLua (
  source
  // {
    version = "0-unstable-${source.date}";

    dontBuild = true;

    scriptPath = "sub-select.lua";

    meta = {
      description = "Automatically skip chapters based on title";
      homepage = "https://github.com/CogentRedTester/mpv-sub-select";
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
