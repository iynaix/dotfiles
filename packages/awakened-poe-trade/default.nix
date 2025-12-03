{
  callPackage,
  appimageTools,
  ...
}:
let
  source = (callPackage ../../_sources/generated.nix { }).awakened-poe-trade;
  appimageContents = appimageTools.extract {
    inherit (source) pname version src;
  };
in
appimageTools.wrapType2 (
  source
  // {
    extraInstallCommands = ''
      install -m 444 -D ${appimageContents}/awakened-poe-trade.desktop $out/share/applications/${source.pname}.desktop
      substituteInPlace $out/share/applications/${source.pname}.desktop \
        --replace "Exec=AppRun --sandbox %U" "Exec=awakened-poe-trade --ozone-platform=x11 %U"

      install -m 444 -D ${appimageContents}/awakened-poe-trade.png $out/share/icons/hicolor/128x128/apps/${source.pname}.png
    '';

    meta = {
      platforms = [ "x86_64-linux" ];
    };
  }
)
