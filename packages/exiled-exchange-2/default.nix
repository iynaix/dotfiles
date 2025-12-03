{
  callPackage,
  appimageTools,
  ...
}:
let
  source = (callPackage ../../_sources/generated.nix { }).exiled-exchange-2;
  appimageContents = appimageTools.extract {
    inherit (source) pname version src;
  };
in
appimageTools.wrapType2 (
  source
  // {
    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/exiled-exchange-2.desktop $out/share/applications/${source.pname}.desktop
      substituteInPlace $out/share/applications/${source.pname}.desktop \
        --replace "Exec=AppRun --sandbox %U" "Exec=exiled-exchange-2 --ozone-platform=x11 %U"

      install -m 444 -D ${appimageContents}/exiled-exchange-2.png $out/share/icons/hicolor/128x128/apps/${source.pname}.png
    '';

    meta = {
      platforms = [ "x86_64-linux" ];
    };
  }
)
