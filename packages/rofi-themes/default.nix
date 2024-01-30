{
  lib,
  stdenvNoCC,
  nerdfonts,
  source,
}:
stdenvNoCC.mkDerivation (source
  // {
    version = "unstable-${source.date}";

    buildInputs = [(nerdfonts.override {fonts = ["JetBrainsMono" "Iosevka"];})];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/files
      cp -r $src/files $out
      mkdir -p $out/share/fonts/truetype
      cp $src/fonts/Icomoon-Feather.ttf $out/share/fonts/truetype/feather.ttf

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
