{ self, ... }:
let
  drv =
    {
      sources,
      lib,
      appimageTools,
      commandLineArgs ? [ ],
      ...
    }:
    let
      source = sources.exiled-exchange-2;
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
            --replace "Exec=AppRun --sandbox %U" "Exec=exiled-exchange-2 ${lib.escapeShellArgs commandLineArgs} %U"

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
