{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "mpv-nextfile";
  version = "8bf148eec9773c6f663b0d2ac49993340cb18b01";

  src = fetchFromGitHub {
    owner = "jonniek";
    repo = "mpv-nextfile";
    rev = finalAttrs.version;
    hash = "sha256-gDecwfeUU1fTx0nSdpWFO1h0lGVJNkIVps2VEE0wnas=";
  };

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
  };
})
