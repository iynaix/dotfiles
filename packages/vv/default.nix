{
  lib,
  stdenvNoCC,
  makeWrapper,
  file,
  imagemagick,
  source,
}:
# based off derivation for lsix
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/tools/graphics/lsix/default.nix
stdenvNoCC.mkDerivation (
  source
  // {
    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall
      install -Dm755 vv -t $out/bin
      runHook postInstall
    '';

    postFixup = ''
      wrapProgram $out/bin/vv \
        --prefix PATH : ${lib.makeBinPath [file imagemagick]}
    '';

    meta = {
      homepage = "https://github.com/hackerb9/vv";
      description = "A simple image viewer for video terminals capable of sixel graphics.";
      license = lib.licenses.gpl3;
      maintainers = [lib.maintainers.iynaix];
    };
  }
)
