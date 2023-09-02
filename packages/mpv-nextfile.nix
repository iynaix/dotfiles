{
  lib,
  stdenvNoCC,
  sources,
}:
stdenvNoCC.mkDerivation (
  sources.mpv-nextfile
  // {
    version = "unstable-${sources.mpv-chapterskip.date}";

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/mpv/scripts
      cp nextfile.lua $out/share/mpv/scripts/nextfile.lua

      runHook postInstall
    '';

    passthru.scriptName = "nextfile.lua";

    meta = {
      description = "Force open next or previous file in the currently playing files directory";
      homepage = "https://github.com/jonniek/mpv-nextfile";
      license = lib.licenses.unlicense;
      maintainers = with lib.maintainers; [iynaix];
    };
  }
)
