{
  lib,
  stdenvNoCC,
  makeWrapper,
  libnotify,
  rofi,
}:
stdenvNoCC.mkDerivation {
  pname = "rofi-epub-menu";
  version = "1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    install -D ./rofi-epub-menu.sh $out/bin/rofi-epub-menu

    wrapProgram $out/bin/rofi-epub-menu \
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
    mainProgram = "rofi-epub-menu";
    platforms = platforms.all;
  };
}
