{
  lib,
  stdenv,
  fetchFromGitHub,
  substituteAll,
  python3,
  installShellFiles,
  makeWrapper,
  wrapQtAppsHook,
  advancecomp,
  jpegoptim,
  optipng,
  pngcrush,
}: let
  pythonEnv = python3.withPackages (ps: [ps.pyqt5]);
in
  stdenv.mkDerivation {
    pname = "trimage";
    version = "1.0.7-dev";

    src = fetchFromGitHub {
      owner = "Kilian";
      repo = "Trimage";
      rev = "ad74684272a31eee6af289cc59fd90fd962d2806";
      hash = "sha256-jdcGGTqr3f3Xnp6thYmASQYiZh9nagLUTmlFnJ5Hqmc=";
    };

    patches = [
      (substituteAll {
        src = ./use-nix-paths.patch;
        advpng = "${advancecomp}/bin/advpng";
        jpegoptim = "${jpegoptim}/bin/jpegoptim";
        optipng = "${optipng}/bin/optipng";
        pngcrush = "${pngcrush}/bin/pngcrush";
      })
    ];

    nativeBuildInputs = [
      installShellFiles
      makeWrapper
      wrapQtAppsHook
    ];

    dontWrapQtApps = true;

    installPhase = ''
      runHook preInstall

      mkdir $out
      cp -R trimage $out

      installManPage doc/trimage.1
      install -Dm444 desktop/trimage.desktop -t $out/share/applications
      install -Dm444 desktop/trimage.svg -t $out/share/icons/hicolor/scalable/apps

      makeWrapper ${pythonEnv}/bin/python $out/bin/trimage \
            --add-flags "$out/trimage/trimage.py" \
            "''${qtWrapperArgs[@]}"

      runHook postInstall
    '';

    meta = {
      homepage = "https://github.com/Kilian/Trimage";
      description = "A cross-platform tool for optimizing PNG and JPG files";
      license = lib.licenses.mit;
    };
  }
