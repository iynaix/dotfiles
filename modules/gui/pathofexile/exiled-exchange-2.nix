{
  packages =
    {
      inputs,
      pkgs,
      ...
    }:
    let
      drv =
        {
          lib,
          appimageTools,
          commandLineArgs ? [ ],
          ...
        }:
        let
          pname = "exiled-exchange-2";
          appimageContents = appimageTools.extract {
            inherit pname;
            version = inputs._meta.${pname}.tag;
            src = inputs.${pname};
          };
        in
        appimageTools.wrapType2 {
          # name = pname;
          inherit pname;
          version = inputs._meta.${pname}.tag;
          src = inputs.${pname};

          extraInstallCommands = ''
            install -m 444 -D ${appimageContents}/exiled-exchange-2.desktop $out/share/applications/${pname}.desktop
            substituteInPlace $out/share/applications/${pname}.desktop \
              --replace "Exec=AppRun --sandbox %U" "Exec=exiled-exchange-2 ${lib.escapeShellArgs commandLineArgs} %U"

            install -m 444 -D ${appimageContents}/exiled-exchange-2.png $out/share/icons/hicolor/128x128/apps/${pname}.png
          '';

          meta = {
            platforms = [ "x86_64-linux" ];
          };
        };
    in
    {
      exiled-exchange-2 = pkgs.callPackage drv { };
    };
}
