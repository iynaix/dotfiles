{
  lib,
  stdenvNoCC,
  source,
}:
stdenvNoCC.mkDerivation (
  source
  // {
    version = "unstable-${source.date}";

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/mpv/scripts
      cp player/lua/osc.lua $out/share/mpv/scripts/thumbfast-osc.lua

      runHook postInstall
    '';

    passthru.scriptName = "thumbfast-osc.lua";

    meta = {
      description = "High-performance on-the-fly thumbnailer for mpv";
      homepage = "https://github.com/po5/thumbfast/vanilla-osc";
      license = lib.licenses.mpl20;
      maintainers = [lib.maintainers.iynaix];
    };
  }
)
