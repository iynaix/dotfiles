{
  hosts = [ "desktop" ];

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
          commandLineArgs ? [ "--ozone-platform=x11" ],
          ...
        }:
        let
          pname = "exiled-exchange-2";
        in
        appimageTools.wrapType2 (finalAttrs: {
          inherit pname;
          inherit (inputs._meta.${pname}) version;
          src = inputs.${pname};

          extraInstallCommands = ''
            install -m 444 -D ${finalAttrs.contents}/exiled-exchange-2.desktop $out/share/applications/${pname}.desktop
            substituteInPlace $out/share/applications/${pname}.desktop \
              --replace-fail "Exec=AppRun --sandbox %U" "Exec=exiled-exchange-2 ${lib.escapeShellArgs commandLineArgs} %U"

            install -m 444 -D ${finalAttrs.contents}/exiled-exchange-2.png $out/share/icons/hicolor/128x128/apps/${pname}.png
          '';

          meta = {
            platforms = [ "x86_64-linux" ];
            mainProgram = "exiled-exchange-2";
          };
        });
    in
    {
      exiled-exchange-2 = pkgs.callPackage drv { };
    };

  config = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.custom.exiled-exchange-2
    ];

    custom.programs = {
      umbriel.settings = {
        window_rule = [
          {
            match.title = "Exiled Exchange 2";
            default_floating = true;
            blur = false;
          }
        ];
      };
    };

    custom.persist = {
      home.directories = [
        ".config/exiled-exchange-2"
      ];
    };
  };
}
