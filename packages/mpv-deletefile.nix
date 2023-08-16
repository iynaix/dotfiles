{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "mpv-deletefile";
  version = "19ea069abcb794d1bf8fac2f59b50d71ab992130";

  src = fetchFromGitHub {
    owner = "zenyd";
    repo = "mpv-scripts";
    rev = finalAttrs.version;
    hash = "sha256-OBCuzCtgfSwj0i/rBNranuu4LRc47jObwQIJgQQoerg=";
  };

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
  };
})
