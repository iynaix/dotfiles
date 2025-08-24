{
  lib,
  callPackage,
  mpvScripts,
}:
let
  source = (callPackage ./generated.nix { }).mpv-cut;
in
mpvScripts.buildLua (
  source
  // {
    version = "0-unstable-${source.date}";

    dontBuild = true;

    scriptPath = "main.lua";

    meta = {
      description = "An mpv plugin for cutting videos incredibly quickly.";
      homepage = "https://github.com/familyfriendlymikey/mpv-cut";
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
