{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  name = "mpv-thumbfast-osc";
  version = "74cba1fa846fb4bec2ce8a92b7b0b0a3209f8c2a";

  src = fetchFromGitHub {
    owner = "po5";
    repo = "thumbfast";
    rev = finalAttrs.version;
    hash = "sha256-S8x1DkvwKF83Po+HA5YLS7g4p4odKwDm3oP61VnbFFs=";
  };

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
  };
})
