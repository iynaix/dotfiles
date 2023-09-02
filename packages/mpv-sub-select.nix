{
  stdenvNoCC,
  lib,
  sources,
}:
stdenvNoCC.mkDerivation (
  sources.mpv-sub-select
  // {
    version = "unstable-${sources.mpv-sub-select.date}";

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/mpv/scripts
      cp sub-select.lua $out/share/mpv/scripts/sub-select.lua

      runHook postInstall
    '';

    passthru.scriptName = "sub-select.lua";

    meta = {
      description = "Automatiacally skip chapters based on title";
      homepage = "https://github.com/CogentRedTester/mpv-sub-select";
      maintainers = with lib.maintainers; [iynaix];
    };
  }
)
