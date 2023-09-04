{
  stdenvNoCC,
  lib,
  sources,
}:
stdenvNoCC.mkDerivation (
  sources.mpv-chapterskip
  // {
    version = "unstable-${sources.mpv-chapterskip.date}";

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/mpv/scripts
      cp chapterskip.lua $out/share/mpv/scripts/chapterskip.lua

      runHook postInstall
    '';

    passthru.scriptName = "chapterskip.lua";

    meta = {
      description = "Automatically skip chapters based on title";
      homepage = "https://github.com/po5/chapterskip";
      maintainers = with lib.maintainers; [iynaix];
    };
  }
)
