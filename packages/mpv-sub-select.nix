{
  stdenvNoCC,
  fetchFromGitHub,
  lib,
}:
stdenvNoCC.mkDerivation {
  name = "mpv-sub-select";
  version = "unstable-2023-04-23";

  src = fetchFromGitHub {
    owner = "CogentRedTester";
    repo = "mpv-sub-select";
    rev = "a23111e181b0051854cc543a31bee4f6741183ac";
    hash = "sha256-dwg8Trp6EqiNHrKVn//4V1jEwzZdwt5uFsHSyBOebGI=";
  };

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
