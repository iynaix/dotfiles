{
  lib,
  source,
  stdenvNoCC,
}:
stdenvNoCC.mkDerivation (
  source
  // {
    version = "unstable-${source.date}";

    dontBuild = true;

    installPhase = ''

      runHook preInstall

      mkdir -p $out/share/mpv/scripts
      cp delete_file.lua $out/share/mpv/scripts/deletefile.lua

      runHook postInstall
    '';

    passthru.scriptName = "deletefile.lua";

    meta = {
      description = "Deletes files played through mpv";
      homepage = "https://github.com/zenyd/mpv-scripts";
      license = lib.licenses.gpl3;
      maintainers = [ lib.maintainers.iynaix ];
    };
  }
)
