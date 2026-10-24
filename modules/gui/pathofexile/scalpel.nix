{
  packages =
    {
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      drv =
        {
          appimageTools,
          commandLineArgs ? [ "--ozone-platform=x11" ],
          ...
        }:
        let
          pname = "scalpel";
        in
        appimageTools.wrapType2 (finalAttrs: {
          inherit pname;
          inherit (inputs._meta.${pname}) version;
          src = inputs.${pname};

          extraInstallCommands = ''
            install -m 444 -D ${finalAttrs.contents}/scalpel.desktop $out/share/applications/${pname}.desktop
            cat "$out/share/applications/${pname}.desktop"
            substituteInPlace $out/share/applications/${pname}.desktop \
              --replace-fail "Exec=AppRun --no-sandbox %U" "Exec=scalpel ${lib.escapeShellArgs commandLineArgs} %U"

            install -m 444 -D ${finalAttrs.contents}/scalpel.png $out/share/icons/hicolor/128x128/apps/${pname}.png
          '';

          meta = {
            platforms = [ "x86_64-linux" ];
            mainProgram = "scalpel";
          };
        });
    in
    {
      scalpel = pkgs.callPackage drv { };
    };

  config = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.custom.scalpel
    ];

    custom.persist = {
      home.directories = [
        ".config/scalpel"
      ];
    };
  };
}
