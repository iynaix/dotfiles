{
  lib,
  stdenvNoCC,
  makeWrapper,
  libnotify,
  networkmanager,
  procps,
  rofi,
  grub2,
  hasWindows ? false,
}:
stdenvNoCC.mkDerivation {
  pname = "rofi-power-menu";
  version = "1.1";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    mkdir -p $out/bin
    substitute ./rofi-power-menu.sh $out/bin/rofi-power-menu \
      --replace-fail '${lib.optionalString (!hasWindows) "|$windows"}' ""
    chmod +x $out/bin/rofi-power-menu

    wrapProgram $out/bin/rofi-power-menu \
      --prefix PATH : ${
        lib.makeBinPath [
          procps # for uptime
          libnotify
          networkmanager
          rofi
          grub2
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
