{
  lib,
  stdenvNoCC,
  makeWrapper,
  libnotify,
  networkmanager,
  procps,
  rofi,
  reboot-to-windows ? null,
}:
stdenvNoCC.mkDerivation {
  pname = "rofi-power-menu";
  version = "1.1";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = # sh
    ''
      mkdir -p $out/bin
      ${
        if (reboot-to-windows == null) then
          ''substitute ./rofi-power-menu.sh $out/bin/rofi-power-menu --replace-fail '|$windows' ""''
        else
          "cp ./rofi-power-menu.sh $out/bin/rofi-power-menu"
      }

      chmod +x $out/bin/rofi-power-menu

      wrapProgram $out/bin/rofi-power-menu \
        --prefix PATH : ${
          lib.makeBinPath [
            procps # for uptime
            libnotify
            networkmanager
            rofi
            reboot-to-windows
          ]
        }
    '';

  meta = {
    description = "A huge collection of Rofi based custom Applets, Launchers & Powermenus";
    homepage = "https://github.com/adi1090x/rofi";
    license = lib.licenses.gpl3Only;
    maintainers = [ lib.maintainers.iynaix ];
    mainProgram = "rofi-wifi-menu";
    platforms = lib.platforms.all;
  };
}
