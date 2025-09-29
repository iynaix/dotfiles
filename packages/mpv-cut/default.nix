{
  lib,
  callPackage,
  mpvScripts,
  configLua ? "",
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

    postInstall = lib.optionalString (configLua != "") ''
      mkdir -p $out/share/mpv/scripts
      cat << 'EOF' > $out/share/mpv/scripts/config.lua
      ${configLua}
      EOF
    '';

    meta = {
      description = "An mpv plugin for cutting videos incredibly quickly.";
      homepage = "https://github.com/familyfriendlymikey/mpv-cut";
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
