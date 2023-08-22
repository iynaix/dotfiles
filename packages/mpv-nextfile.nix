{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  name = "mpv-nextfile";
  version = "unstable-2023-08-09";

  src = fetchFromGitHub {
    owner = "jonniek";
    repo = "mpv-nextfile";
    rev = "b8f7a4d6224876bf26724a9313a36e84d9ecfd81";
    hash = "sha256-Ad98iUbumhsudGwHcYEVTV6ye6KHj5fHAx8q90UQ2QM=";
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
    maintainers = with lib.maintainers; [iynaix];
  };
}
