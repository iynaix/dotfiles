{
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "mpv-subsearch";
  version = "9a5cda4fc8f0896cec27dca60a32251009c0e9c5";

  src = fetchFromGitHub {
    owner = "kelciour";
    repo = "mpv-scripts";
    rev = finalAttrs.version;
    hash = "sha256-BRyKJeXWFhsCDKTUNKsp+yqYpP9mzbaZMviUFXyA308=";
  };

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
  };
})
