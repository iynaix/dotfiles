{ self, ... }:
let
  drv =
    {
      sources,
      lib,
      appimageTools,
      killall,
      writeShellApplication,
      ...
    }:
    let
      source = sources.awakened-poe-trade;
      appimageContents = appimageTools.extract {
        inherit (source) pname version src;
      };
      # kill previous instance if any before launching
      wrapped = writeShellApplication {
        name = "awakened-poe-trade";
        runtimeInputs = [ killall ];
        text = ''
          killall "awakened-poe-trade" || awakened-poe-trade --ozone-platform=x11 "$@"
        '';
      };
    in
    appimageTools.wrapType2 (
      source
      // {
        extraInstallCommands = ''
          install -m 444 -D ${appimageContents}/awakened-poe-trade.desktop $out/share/applications/${source.pname}.desktop
          substituteInPlace $out/share/applications/${source.pname}.desktop \
            --replace "Exec=AppRun --sandbox %U" "Exec=${lib.getExe wrapped} %U"

          install -m 444 -D ${appimageContents}/awakened-poe-trade.png $out/share/icons/hicolor/128x128/apps/${source.pname}.png
        '';

        meta = {
          platforms = [ "x86_64-linux" ];
        };
      }
    );
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.awakened-poe-trade = pkgs.callPackage drv {
        sources = self.libCustom.nvFetcherSources pkgs;
      };
    };
}
