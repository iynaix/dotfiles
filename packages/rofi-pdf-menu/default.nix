{
  lib,
  stdenvNoCC,
  makeWrapper,
  libnotify,
  rofi,
}:
stdenvNoCC.mkDerivation {
  pname = "rofi-pdf-menu";
  version = "1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    install -D ./rofi-pdf-menu.sh $out/bin/rofi-pdf-menu

    wrapProgram $out/bin/rofi-pdf-menu \
      --prefix PATH : ${
        lib.makeBinPath [
          libnotify
          rofi
        ]
      }
  '';

  meta = with lib; {
    # description = "A huge collection of Rofi based custom Applets, Launchers & Powermenus";
    # homepage = "https://github.com/adi1090x/rofi";
    # license = licenses.gpl3Only;
    # maintainers = with maintainers; [ iynaix ];
    mainProgram = "rofi-pdf-menu";
    platforms = platforms.all;
  };
}
