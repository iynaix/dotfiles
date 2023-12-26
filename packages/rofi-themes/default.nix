{
  lib,
  stdenv,
  source,
}:
stdenv.mkDerivation (source
  // {
    installPhase = ''
      runHook preInstall
      cp -r files $out
      runHook postInstall
    '';

    meta = with lib; {
      description = "A huge collection of Rofi based custom Applets, Launchers & Powermenus";
      homepage = "https://github.com/adi1090x/rofi";
      license = licenses.gpl3Only;
      maintainers = with maintainers; [iynaix];
      mainProgram = "rofi-themes";
      platforms = platforms.all;
    };
  })
