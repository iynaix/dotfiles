{
  lib,
  stdenvNoCC,
  source,
}:
stdenvNoCC.mkDerivation (
  source
  // {
    version = "unstable-${source.date}";

    installPhase = ''
      runHook preInstall

      # the fonts will be picked up by rofi in an override plugins = [ rofi-themes ];
      mkdir -p $out/share/fonts/truetype
      cp -r $src/files/* $out
      cp $src/fonts/Icomoon-Feather.ttf $out/share/fonts/truetype

      runHook postInstall
    '';

    meta = with lib; {
      description = "A huge collection of Rofi based custom Applets, Launchers & Powermenus";
      homepage = "https://github.com/adi1090x/rofi";
      license = licenses.gpl3Only;
      maintainers = with maintainers; [ iynaix ];
      mainProgram = "rofi-themes";
      platforms = platforms.all;
    };
  }
)
