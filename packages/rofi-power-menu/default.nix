{
  lib,
  stdenvNoCC,
  makeWrapper,
  libnotify,
  networkmanager,
  rofi,
}:
stdenvNoCC.mkDerivation {
  pname = "rofi-power-menu";
  version = "1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    install -D ./rofi-power-menu.sh $out/bin/rofi-power-menu

    wrapProgram $out/bin/rofi-power-menu \
      --prefix PATH : ${
        lib.makeBinPath [
          libnotify
          networkmanager
          rofi
        ]
      }
  '';

  meta = with lib; {
    description = "A huge collection of Rofi based custom Applets, Launchers & Powermenus";
    homepage = "https://github.com/adi1090x/rofi";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ iynaix ];
    mainProgram = "rofi-wifi-menu";
    platforms = platforms.all;
  };
}
