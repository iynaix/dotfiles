{
  lib,
  callPackage,
  appimageTools,
  makeWrapper,
  killall,
  writeShellApplication,
}:
let
  source = (callPackage ../../_sources/generated.nix { }).exiled-exchange-2;
  appimageContents = appimageTools.extract {
    inherit (source) pname version src;
  };
  wrapped = writeShellApplication {
    name = "exiled-exchange-2";
    runtimeInputs = [ killall ];
    text = ''
      killall "exiled-exchange-2" || exiled-exchange-2 --ozone-platform=x11 "$@"
    '';
  };
in
appimageTools.wrapType2 (
  source
  // {
    nativeBuildInputs = [ makeWrapper ];

    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/exiled-exchange-2.desktop $out/share/applications/${source.pname}.desktop
      substituteInPlace $out/share/applications/${source.pname}.desktop \
        --replace-fail "Exec=AppRun --sandbox %U" "Exec=${lib.getExe wrapped} %U"

      install -m 444 -D ${appimageContents}/exiled-exchange-2.png $out/share/icons/hicolor/128x128/apps/${source.pname}.png

      # fix not being clickable
      # https://github.com/Kvan7/Exiled-Exchange-2/issues/793#issuecomment-3694045386
      wrapProgram $out/bin/exiled-exchange-2 --set XDG_SESSION_TYPE x11
    '';

    meta = {
      platforms = [ "x86_64-linux" ];
    };
  }
)
