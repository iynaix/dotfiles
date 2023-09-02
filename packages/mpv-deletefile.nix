{
  lib,
  stdenvNoCC,
  sources,
}:
stdenvNoCC.mkDerivation (
  sources.mpv-deletefile
  // {
    version = "unstable-${sources.mpv-chapterskip.date}";

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
      maintainers = with lib.maintainers; [iynaix];
    };
  }
)
