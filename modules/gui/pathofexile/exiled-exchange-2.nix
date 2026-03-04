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
      source = sources.exiled-exchange-2;
      appimageContents = appimageTools.extract {
        inherit (source) pname version src;
      };
      # kill previous instance if any before launching
      wrapped = writeShellApplication {
        name = "exiled-exchange-2";
        runtimeInputs = [ killall ];
        text = ''
          # fix not being clickable
          # https://github.com/Kvan7/Exiled-Exchange-2/issues/793#issuecomment-3694045386
          killall "exiled-exchange-2" || XDG_SESSION_TYPE=x11 exiled-exchange-2 --ozone-platform=x11 "$@"
        '';
      };
    in
    appimageTools.wrapType2 (
      source
      // {
        extraInstallCommands = ''
          install -m 444 -D ${appimageContents}/exiled-exchange-2.desktop $out/share/applications/${source.pname}.desktop
          substituteInPlace $out/share/applications/${source.pname}.desktop \
            --replace "Exec=AppRun --sandbox %U" "Exec=${lib.getExe wrapped} %U"

          install -m 444 -D ${appimageContents}/exiled-exchange-2.png $out/share/icons/hicolor/128x128/apps/${source.pname}.png
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
      packages.exiled-exchange-2 = pkgs.callPackage drv {
        sources = self.libCustom.nvFetcherSources pkgs;
      };
    };
}
