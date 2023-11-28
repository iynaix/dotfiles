{
  stdenvNoCC,
  fetchzip,
  lib,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mpv-anime4k";
  version = "4.0.1";

  src = fetchzip {
    url = "https://github.com/bloc97/Anime4K/releases/download/v${finalAttrs.version}/Anime4K_v4.0.zip";
    hash = "sha256-9B6U+KEVlhUIIOrDauIN3aVUjZ/gQHjFArS4uf/BpaM=";
    # archive does not contain a single folder at the root
    stripRoot = false;
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/mpv/shaders
    cp * $out/share/mpv/shaders

    runHook postInstall
  '';

  passthru.scriptName = "";

  meta = with lib; {
    description = "Anime4K is a set of open-source, high-quality real-time anime upscaling/denoising algorithms that can be implemented in any programming language.";
    homepage = "https://github.com/bloc97/Anime4K";
    license = licenses.mit;
    maintainers = [lib.maintainers.iynaix];
  };
})
