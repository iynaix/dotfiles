{
  hosts = [ "desktop" ];

  packages =
    { inputs, pkgs, ... }:
    let
      pname = "awakened-poe-trade";
      drv =
        {
          lib,
          stdenv,
          appimageTools,
          makeWrapper,
          electron,
          libxtst,
          libxt,
          commandLineArgs ? [ "--ozone-platform=x11" ],
        }:
        stdenv.mkDerivation (finalAttrs: {
          inherit pname;
          inherit (inputs._meta.${pname}) version;
          src = inputs.${pname};

          dontUnpack = true;
          dontConfigure = true;
          dontBuild = true;

          passthru = {
            appImageContents = appimageTools.extract {
              inherit (finalAttrs) pname src version;
            };
          };

          nativeBuildInputs = [ makeWrapper ];

          installPhase = ''
            runHook preInstall
            mkdir -p $out/bin $out/share/awakened-poe-trade $out/share/applications

            cp -a ${finalAttrs.passthru.appImageContents}/{locales,resources} $out/share/awakened-poe-trade
            cp -a ${finalAttrs.passthru.appImageContents}/awakened-poe-trade.desktop $out/share/applications/
            cp -a ${finalAttrs.passthru.appImageContents}/usr/share/icons $out/share

            substituteInPlace $out/share/applications/awakened-poe-trade.desktop \
              --replace-fail 'Exec=AppRun' 'Exec=awakened-poe-trade ${lib.escapeShellArgs commandLineArgs}'

            runHook postInstall
          '';

          postFixup = ''
            makeWrapper ${lib.getExe electron} $out/bin/awakened-poe-trade \
              --add-flags $out/share/awakened-poe-trade/resources/app.asar \
              ${
                lib.optionalString (commandLineArgs != [ ]) "--add-flags ${lib.escapeShellArgs commandLineArgs}"
              } \
              --prefix LD_LIBRARY_PATH : "${
                lib.makeLibraryPath [
                  libxtst
                  libxt
                ]
              }"
          '';

          meta = {
            platforms = with lib.platforms; linux;
            mainProgram = "awakened-poe-trade";
          };
        });
    in
    {
      awakened-poe-trade = pkgs.callPackage drv { };
    };

  config = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.custom.awakened-poe-trade
    ];

    custom.programs = {
      umbriel.settings = {
        window_rule = [
          {
            match.title = "Awakened PoE Trade";
            default_floating = true;
            blur = false;
          }
        ];
      };
    };

    custom.persist = {
      home.directories = [
        ".config/awakened-poe-trade"
      ];
    };
  };
}
