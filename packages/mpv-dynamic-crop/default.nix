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
      cp dynamic-crop.lua $out/share/mpv/scripts/dynamic-crop.lua

      runHook postInstall
    '';

    passthru.scriptName = "dynamic-crop.lua";

    meta = {
      description = ''Script to "cropping" dynamically, hard-coded black bars detected with lavfi-cropdetect filter for Ultra Wide Screen or any screen (Smartphone/Tablet).'';
      homepage = "https://github.com/Ashyni/mpv-scripts";
      license = lib.licenses.mit;
      maintainers = [lib.maintainers.iynaix];
    };
  }
)
