{
  stdenvNoCC,
  lib,
  sources,
}:
stdenvNoCC.mkDerivation (
  sources.mpv-subsearch
  // {
    version = "unstable-${sources.mpv-subsearch.date}";

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/mpv/scripts
      cp sub-search.lua $out/share/mpv/scripts/sub-search.lua

      runHook postInstall
    '';

    passthru.scriptName = "sub-search.lua";

    meta = {
      description = "Search for a phrase in subtitles and skip to it";
      homepage = "https://github.com/kelciour/mpv-scripts";
      maintainers = with lib.maintainers; [iynaix];
    };
  }
)
