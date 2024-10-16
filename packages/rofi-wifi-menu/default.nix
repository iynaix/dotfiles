{
  lib,
  fetchFromGitHub,
  stdenvNoCC,
  makeWrapper,
  libnotify,
  networkmanager,
}:
stdenvNoCC.mkDerivation {
  pname = "rofi-wifi-menu";
  version = "unstable-2023-11-23";

  src = fetchFromGitHub {
    owner = "ericmurphyxyz";
    repo = "rofi-wifi-menu";
    rev = "d6debde6e302f68d8235ced690d12719124ff18e";
    hash = "sha256-H+vBRdGcSDMKGLHhPB7imV148O8GRTMj1tZ+PLQUVG4=";
  };

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    install -D ./rofi-wifi-menu.sh $out/bin/rofi-wifi-menu

    wrapProgram $out/bin/rofi-wifi-menu \
      --prefix PATH : ${
        lib.makeBinPath [
          libnotify
          networkmanager
        ]
      }
  '';

  meta = {
    description = "A bash script using nmcli and rofi to make a wifi menu for your favorite window manager";
    homepage = "https://github.com/ericmurphyxyz/rofi-wifi-menu";
    license = lib.licenses.unfree; # nix-init did not find a license
    maintainers = with lib.maintainers; [ iynaix ];
    mainProgram = "rofi-wifi-menu";
    platforms = lib.platforms.all;
  };
}
